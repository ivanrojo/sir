class MachinesController < ApplicationController
  before_filter :authentication_required, :except => [:get_file]
  before_filter :user_is_admin, :except => [:my_mailer,:get_file, :list_user_machines, :contact_mail]
  
  set_params_from_atom :machine, :only => [ :create, :update ]
  
  # GET /machines
  # GET /machines.xml
  # GET /machines.atom
  def index
    session[:current_tab] = "Manage"
    session[:current_sub_tab] = "Resources"
    @machines = Machine.find(:all)
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @machines }
      format.atom
    end
  end
  
  # GET /machines/1
  # GET /machines/1.xml
  # GET /machines/1.atom
  def show
    @machine = Machine.find(params[:id])
    
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @machine }
      format.atom
    end
  end
  
  # GET /machines/new
  # GET /machines/new.xml
  def new
    @machine = Machine.new
    
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @machine }
    end
  end
  
  # GET /machines/1/edit
  def edit
    @machine = Machine.find(params[:id])
  end
  
  # POST /machines
  # POST /machines.xml
  # POST /machines.atom
  def create
    name = params[:machine][:name]
    nickname = params[:machine][:nickname]

    @machine = Machine.new(params[:machine])
    
    respond_to do |format|
      if @machine.save
        flash[:notice] = 'Machine was successfully created.'
        format.html { redirect_to machines_path }
        format.xml  { render :xml => @machine, :status => :created, :location => @machine }
        format.atom { 
          headers["Location"] = formatted_machine_url(@machine, :atom )
          render :action => 'show',
                 :status => :created
        }
      else
        format.html { 
        @machines = Machine.all
        render :action => :index }
        format.xml  { render :xml => @machine.errors, :status => :unprocessable_entity }
        format.atom { render :xml => @machine.errors.to_xml, :status => :bad_request }
      end
    end
  end
  
  # PUT /machines/1
  # PUT /machines/1.xml
  # PUT /machines/1.atom
  # if params[:assign_to_everybody] then assigns the machine to every user
  def update
    
    @machine = Machine.find(params[:id])
    
    respond_to do |format|
      if @machine.update_attributes(params[:machine])
        
        flash[:notice] = 'Machine was successfully updated.'
        format.html { redirect_to machines_path() }
        format.xml  { head :ok }
        format.atom { head :ok }        
      else
        format.html { @machines = Machine.all 
          render :action => "index" }
        format.xml  { render :xml => @machine.errors, :status => :unprocessable_entity }
        format.atom { render :xml => @machine.errors.to_xml, :status => :not_acceptable }
      end
    end
  end
  
  # DELETE /machines/1
  # DELETE /machines/1.xml
  # DELETE /machines/1.atom
  def destroy
    @machine = Machine.find(params[:id])
    @machine.destroy
    
    respond_to do |format|
      format.html { redirect_to machines_path }
      format.xml  { head :ok }
      format.atom { head :ok }
    end
  end
  
  def contact_mail  
    #no hace nada
  end
  
  #this method is used in the contact form used to ask for more resources. This check some params
  def my_mailer     
    from_email = params[:comment][:email]  
    message = params[:comment][:message]  
    begin
      #First check if the senders email is valid
      if from_email =~ /^[a-zA-Z0-9._%-]+@(?:[a-zA-Z0-9-]+\.)+[a-zA-Z]{2,4}$/
        #put all the contents of my form in a hash
        mail_info = {"from_name" => current_user.login,"user_email" => current_user.email, "from_email" => from_email, "message" => message}
        #Call the Notifier class and send the email
        Notifier.deliver_contact_mail(mail_info)
        #Display a message notifying the sender that his email was delivered.
        flash[:notice] = 'Your message was successfully delivered to the SIR Administrator.'
        #Then redirect to index or any page you want with the message
        redirect_to(:action => 'contact_mail')  
      else
        #if the senders email address is not valid
        #display a warning and redirect to any action you want
        flash[:warning] = 'Your email address appears to be invalid.'
        redirect_to(:action => 'contact_mail')
      end  
    rescue
      #if everything fails, display a warning and the exception
      #Maybe not always advisable if your app is public
      #But good for debugging, especially if action mailer is setup wrong
      flash[:warning] = "Your message could not be delivered at this time. #$!. Please try again later"
      redirect_to(:action => 'contact_mail') end
  end
  
  
end
