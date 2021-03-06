require 'vpim/vcard'

class ProfilesController < ApplicationController
  before_filter :authentication_required

  before_filter :get_user
  
  authorization_filter :profile, :read,   :only => [ :show ]
  authorization_filter :profile, :manage, :except => [ :show ]

  before_filter :unique_profile, :only=> [:new, :create]
  
  set_params_from_atom :profile, :only => [ :create, :update ]
    
  # GET /profile
  # GET /profile.xml
  # if params[:hcard] then hcard is rendered
  # GET /profile.atom
  def show
    session[:current_tab] = "Profile"
    session[:current_sub_tab] = ""

    if params[:hcard]
      hcard
      return
    end
    
    @user_spaces = @user.stages
    if @user.profile.new_record? && current_user == @user
      flash[:notice]= 'You must create your profile first'
      redirect_to new_user_profile_path(@user)
    elsif current_user != @user && @user.profile.new_record?
      flash[:notice]= "Action Not Allowed"
      redirect_to root_path()  
    else
      @thumbnail = Logotype.find(:first, :conditions => {:parent_id => @user.profile.logotype, :thumbnail => 'photo'})  
      respond_to do |format|
        format.html 
        format.xml  { render :xml => @profile }
        format.vcf  { vcard }
        format.atom
      end
    end
  end
  
  # GET /profile/new
  # GET /profile/new.xml
  def new
    session[:current_tab] = "Profile" 
    @user = User.find_by_id(params[:user_id])
    @profile = Profile.new
    
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @profile }
    end
  end
  
  # GET /profiles/edit
  def edit
    session[:current_tab] = "Profile" 
    session[:current_sub_tab] = "Edit Your Profile"

    if @profile.new_record?
      flash[:notice]= 'You must create your profile first'
      redirect_to new_user_profile_path(@user )
    else
      @thumbnail = Logotype.find(:first, :conditions => {:parent_id => @user.profile.logotype, :thumbnail => 'photo'})
      @user = User.find_by_id(params[:user_id])      
    end
  end
  
  
  # POST /profile
  # POST /profile.xml
  # POST /profile.atom
  def create
    @profile = current_user.build_profile(params[:profile])
    @logotype = @profile.build_logotype(params[:logotype]) 

    respond_to do |format|
      if @profile.save
        flash[:notice] = 'Profile was successfully created.'
        format.html { redirect_to :action => 'show' }
        format.xml  { render :xml => @profile, :status => :created, :location => @profile }
        format.atom { 
          headers["Location"] = formatted_user_profile_url(@user, :atom )
          render :action => 'show',
                 :status => :created
        }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @profile.errors, :status => :unprocessable_entity }
        format.atom { render :xml => @profile.errors.to_xml, :status => :bad_request }
      end
    end
  end
  
  # PUT /profile
  # PUT /profile.xml
  # PUT /profile.atom
  def update
    #En primer lugar miro si se ha eliminado la foto del usuario y la borro de la base de datos
    if params[:delete_thumbnail] && params[:delete_thumbnail] == "true"
        @profile.logotype = nil 
    end
    
    if params[:logotype] && params[:logotype]!= {"uploaded_data"=>""}
       @logotype = Logotype.new(params[:logotype]) 
       if !@logotype.valid?
          flash[:error] = "The logotype is not valid"  
          render :action => "edit"   
          return
       end
       @profile.logotype = @logotype
    end
    
    respond_to do |format|
      @thumbnail = Logotype.find(:first, :conditions => {:parent_id => @user.profile.logotype, :thumbnail => 'photo'})
      if @profile.update_attributes(params[:profile])
        flash[:notice] = 'Profile was successfully updated.'
        format.html { render :action => "show" }
        format.xml  { head :ok }
        format.atom { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @profile.errors, :status => :unprocessable_entity }
        format.atom { render :xml => @profile.errors.to_xml, :status => :not_acceptable }
      end
    end
  end
  
  # DELETE /profile
  # DELETE /profile.xml
  # DELETE /profile.atom
  def destroy
    @profile.destroy
    flash[:notice] = 'Profile was successfully deleted.'
    respond_to do |format|
      format.html { redirect_to(space_user_profile_url(@space, @user)) }
      format.xml  { head :ok }
      format.atom  { head :ok }
    end
  end
  
  
  private

  def get_user
    @user = params[:user_id] ? User.find(params[:user_id]) : current_user
    @profile = @user.profile || @user.build_profile
  end
  
  #this is used to create the hcard microformat of an user in order to show it in the application
  def hcard
    if @profile.nil?
      flash[:notice]= 'You must create your profile first'
      redirect_to new_space_user_profile_path(@space, :user_id=>current_user.id)
    else
      render :partial=>'hcard'
    end
  end
  
  
  #this method is used to compose the vcard file (.vcf) with the profile of an user
  def vcard
    email = User.find(profile.user_id).email
    @card = Vpim::Vcard::Maker.make2 do |maker|
      maker.add_name do |name|
        name.given = profile.name
        name.family = profile.lastname
      end
      maker.add_addr do |addr|
        addr.preferred = true
        addr.location = 'home'
        addr.street = profile.address
        addr.locality = profile.city
        addr.country = profile.country
        addr.postalcode = profile.zipcode
        addr.region = profile.province
      end
      maker.add_tel(profile.phone) do |tel|
        tel.location = 'work'
        tel.preferred = true
      end
      if profile.mobile == ""
        maker.add_tel('Not defined') do |tel|
          tel.location = 'cell'
        end
      else
        maker.add_tel(profile.mobile) do |tel|
          tel.location = 'cell'
        end  
      end
      if profile.fax == ""
        maker.add_tel('Not defined') do |tel|
          tel.location = 'work'
          tel.capability = 'fax'
        end
      else
        maker.add_tel(profile.fax) do |tel|
          tel.location = 'work'
          tel.capability = 'fax'
        end
      end
      maker.add_email(email) { |e| e.location = 'work' }
    end
    send_data @card.to_s, :filename => "vcard_#{profile.name}.vcf"
  end
  
  #unused method!
  #this method is used when a user want to import his vcard file.
  def import_vcard
    
  end

  def unique_profile
   unless current_user.profile.nil?
     flash[:error] = "You already have a profile."     
     redirect_to user_profile_path(current_user)
   end
 end
end
