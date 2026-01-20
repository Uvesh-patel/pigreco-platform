# frozen_string_literal: true

# =============================================================================
# LOMELLINA FLOOD RISK MANAGEMENT SCENARIO
# =============================================================================
# This seed file implements the Lomellina case study from the PIGRECO D8 report.
# It creates:
#   - 6 Stakeholder User Groups (Civil Protection, Agricultural, University, etc.)
#   - Process Group for coordinating flood risk evaluation
#   - 2 Participatory Processes (Levee Operations, Population Delocalization)
#   - Assembly for final deliberation
#   - Sample proposals and meetings
#
# Compatible with Decidim 0.28.6
# =============================================================================

puts "=== Starting Lomellina Flood Risk Scenario Seeding ==="

# Get prerequisites
organization = Decidim::Organization.first
admin = organization ? Decidim::User.find_by(admin: true, organization: organization) : nil

unless organization && admin
  puts "ERROR: Organization or admin user not found. Run main seeds first."
  puts "  Organization: #{organization ? 'Found' : 'Missing'}"
  puts "  Admin: #{admin ? 'Found' : 'Missing'}"
else

puts "Using organization: #{organization.name}"
puts "Using admin: #{admin.email}"

# =============================================================================
# PHASE 1: STAKEHOLDER USERS AND USER GROUPS
# =============================================================================
puts "\n--- Phase 1: Creating Stakeholder Users and Groups ---"

# Define the 6 stakeholder categories from the Lomellina case study
LOMELLINA_STAKEHOLDERS = [
  {
    group_name: "Protezione Civile - Lomellina",
    group_nickname: "protciv_lomellina",
    group_email: "protezione.civile@lomellina.local",
    group_about: "Primary emergency management authority for the Lomellina region. Responsible for civil protection, emergency response coordination, and risk assessment validation.",
    category: :civil_protection,
    user_name: "Marco Bianchi",
    user_nickname: "m_bianchi_pc",
    user_email: "marco.bianchi@protezione-civile.local",
    user_about: "Civil Protection Director - Lomellina Command",
    extended_data: { phone: "+39 0382 123456", document_number: "PC-LOM-001" }
  },
  {
    group_name: "Terra di Riso - Cooperativa Agricola",
    group_nickname: "terra_riso",
    group_email: "info@terradriso.local",
    group_about: "Agricultural cooperative representing rice farmers in the Lomellina region. Focused on sustainable agriculture and land management in flood-prone areas.",
    category: :agricultural,
    user_name: "Giulia Rossi",
    user_nickname: "g_rossi_agri",
    user_email: "giulia.rossi@terradriso.local",
    user_about: "President of Terra di Riso Agricultural Cooperative",
    extended_data: { phone: "+39 0382 234567", document_number: "CCIAA-PV-12345" }
  },
  {
    group_name: "Politecnico di Milano - Dipartimento Ingegneria Idraulica",
    group_nickname: "polimi_idrau",
    group_email: "idraulica@polimi.local",
    group_about: "University research department providing scientific expertise in hydraulic engineering, flood modeling, and risk assessment methodologies.",
    category: :university,
    user_name: "Prof. Alessandro Ferri",
    user_nickname: "a_ferri_polimi",
    user_email: "alessandro.ferri@polimi.local",
    user_about: "Professor of Hydraulic Engineering - Politecnico di Milano",
    extended_data: { phone: "+39 02 2399 1234", document_number: "POLIMI-DIP-HYD" }
  },
  {
    group_name: "Confcommercio Lomellina",
    group_nickname: "confcomm_lom",
    group_email: "info@confcommercio-lomellina.local",
    group_about: "Trade association representing commercial businesses in Lomellina. Advocates for business continuity and economic protection during flood events.",
    category: :trade_union,
    user_name: "Francesca Colombo",
    user_nickname: "f_colombo_conf",
    user_email: "francesca.colombo@confcommercio.local",
    user_about: "Director of Confcommercio Lomellina",
    extended_data: { phone: "+39 0382 345678", document_number: "CONF-LOM-2024" }
  },
  {
    group_name: "Ecomuseo del Paesaggio Lomellino",
    group_nickname: "ecomuseo_lom",
    group_email: "info@ecomuseo-lomellina.local",
    group_about: "Non-governmental organization focused on environmental conservation and cultural heritage protection in the Lomellina landscape.",
    category: :ngo,
    user_name: "Luca Martinelli",
    user_nickname: "l_martinelli_eco",
    user_email: "luca.martinelli@ecomuseo.local",
    user_about: "Director of Ecomuseo del Paesaggio Lomellino",
    extended_data: { phone: "+39 0382 456789", document_number: "NGO-ECO-001" }
  },
  {
    group_name: "Connessioni di Vita - Comunità Anziani",
    group_nickname: "connessioni_v",
    group_email: "info@connessionidivita.local",
    group_about: "Citizen collective representing elderly community members in Lomellina. Focuses on social impact assessment and vulnerable population needs.",
    category: :citizen_collective,
    user_name: "Maria Teresa Galli",
    user_nickname: "m_galli_cv",
    user_email: "maria.galli@connessionidivita.local",
    user_about: "Community Representative - Connessioni di Vita",
    extended_data: { phone: "+39 0382 567890", document_number: "CIT-CV-2024" }
  }
].freeze

# Store created users and groups for later use
lomellina_users = {}
lomellina_groups = {}

LOMELLINA_STAKEHOLDERS.each do |stakeholder|
  puts "\nProcessing stakeholder: #{stakeholder[:group_name]}"
  
  # Step 1: Create the representative user for this group
  user = Decidim::User.find_or_initialize_by(
    email: stakeholder[:user_email],
    organization: organization
  )
  
  if user.new_record?
    user.assign_attributes(
      name: stakeholder[:user_name],
      nickname: stakeholder[:user_nickname],
      password: "Lomellina2024!Secure",
      password_confirmation: "Lomellina2024!Secure",
      confirmed_at: Time.current,
      locale: "en",
      tos_agreement: true,
      about: stakeholder[:user_about],
      accepted_tos_version: organization.tos_version
    )
    user.skip_confirmation! if user.respond_to?(:skip_confirmation!)
    user.save!
    puts "  Created user: #{stakeholder[:user_name]} (#{stakeholder[:user_email]})"
  else
    # Always reset password and ensure user can login
    # Use reset_password method which properly encrypts via Devise
    user.reset_password("Lomellina2024!Secure", "Lomellina2024!Secure")
    user.confirmed_at ||= Time.current
    user.failed_attempts = 0
    user.locked_at = nil
    user.accepted_tos_version = organization.tos_version
    user.save!(validate: false)
    puts "  User already exists: #{stakeholder[:user_email]} (password reset)"
  end
  
  lomellina_users[stakeholder[:category]] = user
  
  # Step 2: Create the User Group
  # In Decidim 0.28.6, UserGroups are stored in decidim_users table with type = 'Decidim::UserGroup'
  user_group = Decidim::UserGroup.find_or_initialize_by(
    email: stakeholder[:group_email],
    organization: organization
  )
  
  if user_group.new_record?
    user_group.assign_attributes(
      name: stakeholder[:group_name],
      nickname: stakeholder[:group_nickname],
      about: stakeholder[:group_about],
      confirmed_at: Time.current,
      extended_data: stakeholder[:extended_data]
    )
    user_group.save!
    
    # Verify the group using the verify! method (sets verified_at in extended_data)
    # In Decidim 0.28.6, verified_at is stored in extended_data JSON, not as a column
    user_group.verify!
    
    puts "  Created and verified group: #{stakeholder[:group_name]}"
  else
    puts "  Group already exists: #{stakeholder[:group_name]}"
  end
  
  lomellina_groups[stakeholder[:category]] = user_group
  
  # Step 3: Create membership linking user to group
  # The first user becomes the creator/admin of the group
  membership = Decidim::UserGroupMembership.find_or_initialize_by(
    user: user,
    user_group: user_group
  )
  
  if membership.new_record?
    membership.role = "creator"
    membership.save!
    puts "  Created membership: #{user.name} -> #{user_group.name} (creator)"
  else
    puts "  Membership already exists"
  end
end

puts "\n--- Phase 1 Complete: Created #{lomellina_users.size} users and #{lomellina_groups.size} groups ---"

# =============================================================================
# PHASE 2: PROCESS GROUP AND PARTICIPATORY PROCESSES
# =============================================================================
puts "\n--- Phase 2: Creating Process Group and Participatory Processes ---"

# Create the Process Group that coordinates both evaluation processes
process_group = Decidim::ParticipatoryProcessGroup.find_or_initialize_by(
  organization: organization,
  title: { 
    en: "Gestione Rischio Idrogeologico Lomellina 2025",
    it: "Gestione Rischio Idrogeologico Lomellina 2025"
  }
)

if process_group.new_record?
  process_group.assign_attributes(
    description: {
      en: "<p>This Process Group coordinates the participatory evaluation of flood risk mitigation measures for the Lomellina region. It encompasses two main evaluation processes: assessment of levee/embankment operations and evaluation of population delocalization strategies.</p><p>The goal is to develop comprehensive, community-validated flood risk governance decisions through structured stakeholder participation.</p>",
      it: "<p>Questo Gruppo di Processi coordina la valutazione partecipativa delle misure di mitigazione del rischio alluvionale per la regione Lomellina. Comprende due processi principali: valutazione delle operazioni di arginatura e valutazione delle strategie di delocalizzazione della popolazione.</p>"
    },
    group_url: "https://lomellina.pigreco.local",
    developer_group: { en: "Comune di Lomellina - Protezione Civile", it: "Comune di Lomellina - Protezione Civile" },
    local_area: { en: "Lomellina Region, Pavia Province", it: "Regione Lomellina, Provincia di Pavia" },
    meta_scope: { en: "Flood Risk Governance", it: "Governance del Rischio Alluvionale" },
    target: { en: "Citizens, Technical Experts, Local Authorities, Agricultural Cooperatives, Business Associations, Environmental Organizations", it: "Cittadini, Esperti Tecnici, Autorità Locali, Cooperative Agricole, Associazioni di Imprese, Organizzazioni Ambientali" },
    participatory_scope: { en: "Open participation with verified stakeholder groups", it: "Partecipazione aperta con gruppi di stakeholder verificati" },
    participatory_structure: { en: "Three-phase structure: Information & Consultation, Proposal Development, Deliberation & Decision", it: "Struttura a tre fasi: Informazione e Consultazione, Sviluppo Proposte, Deliberazione e Decisione" },
    promoted: true
  )
  process_group.save!
  puts "Created Process Group: #{process_group.title['en']}"
  
  # Create content blocks for the process group homepage
  begin
    Decidim::ContentBlocksCreator.new(process_group).create_default!
    puts "  Created content blocks for process group"
  rescue => e
    puts "  Content blocks note: #{e.message}"
  end
else
  puts "Process Group already exists: #{process_group.title['en']}"
  # Ensure content blocks exist even for existing process groups
  if Decidim::ContentBlock.where(scoped_resource_id: process_group.id).count == 0
    begin
      Decidim::ContentBlocksCreator.new(process_group).create_default!
      puts "  Created missing content blocks for process group"
    rescue => e
      puts "  Content blocks note: #{e.message}"
    end
  end
end

# Define the two participatory processes
LOMELLINA_PROCESSES = [
  {
    slug: "valutazione-misura-arginature",
    title: { 
      en: "Levee and Embankment Operations Evaluation",
      it: "Valutazione Misura Arginature"
    },
    subtitle: {
      en: "Assessment of structural flood defense measures",
      it: "Valutazione delle misure strutturali di difesa dalle alluvioni"
    },
    short_description: {
      en: "Participatory evaluation of levee and embankment operations as flood mitigation measures for the Lomellina region.",
      it: "Valutazione partecipativa delle operazioni di arginatura come misure di mitigazione del rischio alluvionale."
    },
    description: {
      en: "<p>This participatory process evaluates the effectiveness, feasibility, and social acceptance of levee and embankment operations as flood mitigation measures in the Lomellina region.</p><h4>Process Objectives</h4><ul><li>Assess technical specifications for levee operations</li><li>Evaluate environmental and agricultural impacts</li><li>Gather community input on implementation priorities</li><li>Develop consensus-based recommendations</li></ul>",
      it: "<p>Questo processo partecipativo valuta l'efficacia, la fattibilità e l'accettazione sociale delle operazioni di arginatura come misure di mitigazione delle alluvioni nella regione Lomellina.</p>"
    },
    hashtag: "LomellinaArginature"
  },
  {
    slug: "valutazione-delocalizzazione-popolazione",
    title: {
      en: "Population Delocalization Strategy Evaluation",
      it: "Valutazione Delocalizzazione Popolazione"
    },
    subtitle: {
      en: "Assessment of managed retreat and relocation options",
      it: "Valutazione delle opzioni di ritiro gestito e ricollocazione"
    },
    short_description: {
      en: "Participatory evaluation of population delocalization strategies as a long-term flood risk reduction measure.",
      it: "Valutazione partecipativa delle strategie di delocalizzazione della popolazione come misura di riduzione del rischio a lungo termine."
    },
    description: {
      en: "<p>This participatory process evaluates population delocalization as a strategic option for communities in high-risk flood zones within the Lomellina region.</p><h4>Process Objectives</h4><ul><li>Assess social and economic impacts of delocalization</li><li>Identify vulnerable communities and priority areas</li><li>Develop community-supported relocation frameworks</li><li>Design social protection measures for affected populations</li></ul>",
      it: "<p>Questo processo partecipativo valuta la delocalizzazione della popolazione come opzione strategica per le comunità nelle zone ad alto rischio alluvionale.</p>"
    },
    hashtag: "LomellinaDelocalizzazione"
  }
].freeze

# Define the three phases for each process (from D8 report)
PROCESS_PHASES = [
  {
    title: { en: "Phase 1: Information & Consultation", it: "Fase 1: Informazione e Consultazione" },
    description: { 
      en: "<p>Initial phase focusing on information dissemination and stakeholder consultation through surveys and meetings. Technical authorities provide risk data while stakeholder groups contribute local knowledge and concerns.</p>",
      it: "<p>Fase iniziale focalizzata sulla diffusione delle informazioni e consultazione degli stakeholder attraverso sondaggi e incontri.</p>"
    },
    position: 0,
    active: true,
    start_date: Date.current,
    end_date: 2.months.from_now
  },
  {
    title: { en: "Phase 2: Proposal Development", it: "Fase 2: Sviluppo Proposte" },
    description: {
      en: "<p>Second phase enabling structured proposal development through organizational and individual channels. Verified groups submit proposals using their organizational identity for proper attribution and authentication.</p>",
      it: "<p>Seconda fase che consente lo sviluppo strutturato delle proposte attraverso canali organizzativi e individuali.</p>"
    },
    position: 1,
    active: false,
    start_date: 2.months.from_now,
    end_date: 4.months.from_now
  },
  {
    title: { en: "Phase 3: Deliberation & Decision", it: "Fase 3: Deliberazione e Decisione" },
    description: {
      en: "<p>Final phase involving structured deliberation through assemblies and formal decision-making processes. The specialized assembly ensures balanced stakeholder representation with weighted voting procedures.</p>",
      it: "<p>Fase finale che prevede deliberazioni strutturate attraverso assemblee e processi decisionali formali.</p>"
    },
    position: 2,
    active: false,
    start_date: 4.months.from_now,
    end_date: 6.months.from_now
  }
].freeze

lomellina_processes = {}

LOMELLINA_PROCESSES.each do |process_data|
  process = Decidim::ParticipatoryProcess.find_or_initialize_by(
    slug: process_data[:slug],
    organization: organization
  )
  
  if process.new_record?
    process.assign_attributes(
      title: process_data[:title],
      subtitle: process_data[:subtitle],
      short_description: process_data[:short_description],
      description: process_data[:description],
      hashtag: process_data[:hashtag],
      participatory_process_group: process_group,
      promoted: true,
      published_at: Time.current,
      start_date: Date.current,
      end_date: 6.months.from_now,
      developer_group: { en: "PIGRECO Flood Risk Team", it: "Team Rischio Alluvionale PIGRECO" },
      local_area: { en: "Lomellina Region", it: "Regione Lomellina" },
      target: { en: "All stakeholders", it: "Tutti gli stakeholder" },
      participatory_scope: { en: "Open with verified groups", it: "Aperto con gruppi verificati" },
      participatory_structure: { en: "Three-phase evaluation", it: "Valutazione a tre fasi" },
      meta_scope: { en: "Flood Risk Mitigation", it: "Mitigazione Rischio Alluvionale" },
      scopes_enabled: false,
      private_space: false
    )
    process.save!
    puts "Created Process: #{process_data[:title][:en]}"
    
    # Create phases for this process
    PROCESS_PHASES.each do |phase_data|
      step = Decidim::ParticipatoryProcessStep.find_or_initialize_by(
        participatory_process: process,
        position: phase_data[:position]
      )
      
      if step.new_record?
        step.assign_attributes(
          title: phase_data[:title],
          description: phase_data[:description],
          start_date: phase_data[:start_date],
          end_date: phase_data[:end_date],
          active: phase_data[:active]
        )
        step.save!
        puts "  Created Phase: #{phase_data[:title][:en]}"
      end
    end
  else
    puts "Process already exists: #{process_data[:title][:en]}"
  end
  
  lomellina_processes[process_data[:slug]] = process
end

# Add admin role to both processes
lomellina_processes.each do |slug, process|
  role = Decidim::ParticipatoryProcessUserRole.find_or_initialize_by(
    participatory_process: process,
    user: admin,
    role: "admin"
  )
  role.save! if role.new_record?
end

puts "\n--- Phase 2 Complete: Created Process Group and #{lomellina_processes.size} Processes ---"

# =============================================================================
# PHASE 3: LOMELLINA FLOOD RISK ASSEMBLY
# =============================================================================
puts "\n--- Phase 3: Creating Lomellina Flood Risk Assembly ---"

assembly = Decidim::Assembly.find_or_initialize_by(
  slug: "lomellina-flood-risk-assembly",
  organization: organization
)

if assembly.new_record?
  # First check if AssembliesType exists and create one if needed
  assembly_type = nil
  if defined?(Decidim::AssembliesType)
    assembly_type = Decidim::AssembliesType.find_or_create_by!(
      organization: organization,
      title: { en: "Deliberative Assembly", it: "Assemblea Deliberativa" }
    )
  end
  
  assembly.assign_attributes(
    title: {
      en: "Lomellina Flood Risk Decision Assembly",
      it: "Assemblea Decisionale Rischio Alluvionale Lomellina"
    },
    subtitle: {
      en: "Multi-stakeholder deliberative body for flood risk governance",
      it: "Organo deliberativo multi-stakeholder per la governance del rischio alluvionale"
    },
    short_description: {
      en: "The assembly brings together representatives from all verified stakeholder groups to make final decisions on flood risk mitigation strategies through structured deliberation and weighted voting.",
      it: "L'assemblea riunisce rappresentanti di tutti i gruppi di stakeholder verificati per prendere decisioni finali sulle strategie di mitigazione del rischio alluvionale."
    },
    description: {
      en: "<p>The <strong>Lomellina Flood Risk Decision Assembly</strong> serves as the formal deliberative body for approving flood risk governance decisions. It ensures balanced representation from all stakeholder categories while maintaining technical rigor and democratic legitimacy.</p><h4>Assembly Functions</h4><ul><li>Review and validate proposals from participatory processes</li><li>Conduct structured deliberation on mitigation strategies</li><li>Make binding decisions through weighted voting</li><li>Ensure cross-stakeholder coordination and consensus</li></ul>",
      it: "<p>L'<strong>Assemblea Decisionale Rischio Alluvionale Lomellina</strong> funge da organo deliberativo formale per l'approvazione delle decisioni sulla governance del rischio alluvionale.</p>"
    },
    published_at: Time.current,
    promoted: true,
    scopes_enabled: false,
    private_space: false,
    is_transparent: true,
    purpose_of_action: {
      en: "<p>To provide a democratic, transparent, and technically informed decision-making process for flood risk management in Lomellina.</p>",
      it: "<p>Fornire un processo decisionale democratico, trasparente e tecnicamente informato per la gestione del rischio alluvionale.</p>"
    },
    composition: {
      en: "<p>The assembly includes representatives from: Civil Protection, Agricultural Cooperatives, University Research Groups, Trade Associations, Environmental NGOs, and Citizen Collectives.</p>",
      it: "<p>L'assemblea include rappresentanti di: Protezione Civile, Cooperative Agricole, Gruppi di Ricerca Universitaria, Associazioni di Categoria, ONG Ambientali e Collettivi Cittadini.</p>"
    },
    created_by: "others",
    created_by_other: { en: "PIGRECO Project Consortium", it: "Consorzio Progetto PIGRECO" }
  )
  
  # Add assembly type if available
  assembly.assembly_type = assembly_type if assembly_type && assembly.respond_to?(:assembly_type=)
  
  assembly.save!
  puts "Created Assembly: #{assembly.title['en']}"
  
  # Add assembly members from stakeholder groups
  puts "Adding assembly members..."
  lomellina_users.each do |category, user|
    member = Decidim::AssemblyMember.find_or_initialize_by(
      decidim_assembly_id: assembly.id,
      decidim_user_id: user.id
    )
    
    if member.new_record?
      group = lomellina_groups[category]
      # AssemblyMember.position must be one of: president, vice_president, secretary, other
      # We use 'other' for most stakeholder representatives
      position_type = case category
                      when :civil_protection then "president"  # Lead emergency authority
                      when :university then "secretary"        # Technical documentation
                      else "other"                             # All other stakeholders
                      end
      
      member.assign_attributes(
        full_name: user.name,
        position: position_type,
        designation_date: 1.month.ago.to_date,
        birthday: Date.new(1975, 6, 15),
        birthplace: "Lombardia, Italy",
        gender: "Not specified",
        weight: 0
      )
      member.save!
      puts "  Added member: #{user.name} (#{position_type})"
    end
  end
else
  puts "Assembly already exists: #{assembly.title['en']}"
end

# Add admin role to assembly
assembly_admin_role = Decidim::AssemblyUserRole.find_or_initialize_by(
  assembly: assembly,
  user: admin,
  role: "admin"
)
assembly_admin_role.save! if assembly_admin_role.new_record?

# Create content blocks for the assembly homepage
begin
  Decidim::ContentBlocksCreator.new(assembly).create_default!
  puts "  Created content blocks for assembly"
rescue => e
  puts "  Content blocks may already exist: #{e.message}"
end

# Create components for the assembly
assembly_proposals = Decidim::Component.find_or_initialize_by(
  participatory_space: assembly,
  manifest_name: "proposals"
)
if assembly_proposals.new_record?
  assembly_proposals.assign_attributes(
    name: { en: "Assembly Proposals", it: "Proposte Assemblea" },
    published_at: Time.current,
    settings: { vote_limit: 10, comments_enabled: true }
  )
  assembly_proposals.save!
  puts "  Created Proposals component for assembly"
end

assembly_meetings = Decidim::Component.find_or_initialize_by(
  participatory_space: assembly,
  manifest_name: "meetings"
)
if assembly_meetings.new_record?
  assembly_meetings.assign_attributes(
    name: { en: "Assembly Meetings", it: "Riunioni Assemblea" },
    published_at: Time.current,
    settings: { comments_enabled: true }
  )
  assembly_meetings.save!
  puts "  Created Meetings component for assembly"
  
  # Create the final deliberation meeting
  final_meeting = Decidim::Meetings::Meeting.new(
    component: assembly_meetings,
    title: { en: "Final Deliberation Session: Flood Risk Mitigation Decisions", it: "Sessione Deliberativa Finale" },
    description: { en: "<p>Final assembly meeting to deliberate and vote on flood risk mitigation strategies. All stakeholder representatives will present their recommendations.</p>", it: "<p>Riunione finale dell'assemblea per deliberare e votare sulle strategie di mitigazione del rischio alluvionale.</p>" },
    start_time: 2.months.from_now.change(hour: 9),
    end_time: 2.months.from_now.change(hour: 17),
    address: "Palazzo Comunale, Piazza Repubblica 1, Lomellina",
    location: { en: "Municipal Hall - Main Assembly Room", it: "Municipio - Sala Assemblea" },
    location_hints: { en: "Accessible entrance on the left side", it: "Ingresso accessibile sul lato sinistro" },
    registration_terms: { en: "I commit to participating in the full deliberation process.", it: "Mi impegno a partecipare all'intero processo deliberativo." },
    registrations_enabled: true,
    available_slots: 50,
    private_meeting: false,
    transparent: true,
    published_at: Time.current
  )
  final_meeting.author = organization
  final_meeting.save!
  puts "  Created Final Deliberation meeting for assembly"
end

# Create sample proposals for the assembly
assembly_proposals_component = Decidim::Component.find_by(participatory_space: assembly, manifest_name: "proposals")
if assembly_proposals_component && Decidim::Proposals::Proposal.where(component: assembly_proposals_component).count == 0
  puts "Creating assembly proposals..."
  
  assembly_proposals_data = [
    {
      title: { en: "Integrated Flood Warning System Protocol", it: "Protocollo Sistema Allerta Alluvioni Integrato" },
      body: { en: "<p>Proposal to establish an integrated early warning system connecting all stakeholder groups for coordinated flood response. This system will link meteorological services, civil protection, agricultural cooperatives, and community centers.</p>", it: "<p>Proposta per sistema di allerta precoce integrato che connette tutti i gruppi di stakeholder.</p>" },
      group_nickname: "protcivile_lom"
    },
    {
      title: { en: "Agricultural Insurance Framework for Flood Damage", it: "Quadro Assicurativo Agricolo per Danni Alluvionali" },
      body: { en: "<p>Comprehensive insurance framework to protect agricultural investments in flood-prone areas of Lomellina. The framework includes crop damage assessment protocols and rapid compensation mechanisms.</p>", it: "<p>Quadro assicurativo completo per proteggere investimenti agricoli nelle aree soggette ad alluvioni.</p>" },
      group_nickname: "terradriso_coop"
    },
    {
      title: { en: "Community Resilience Training Program", it: "Programma Formazione Resilienza Comunitaria" },
      body: { en: "<p>Training program for vulnerable populations on flood preparedness and emergency response procedures. Special focus on elderly residents and those with mobility challenges.</p>", it: "<p>Programma di formazione per popolazioni vulnerabili sulla preparazione alle alluvioni.</p>" },
      group_nickname: "connessioni_vita"
    }
  ]
  
  assembly_proposals_data.each do |pd|
    group = Decidim::UserGroup.find_by(nickname: pd[:group_nickname])
    proposal = Decidim::Proposals::Proposal.new(
      component: assembly_proposals_component,
      title: pd[:title],
      body: pd[:body],
      published_at: Time.current
    )
    proposal.add_coauthor(group || organization)
    proposal.save!
    puts "  Created assembly proposal: #{pd[:title][:en][0..40]}..."
  end
end

puts "\n--- Phase 3 Complete: Created Assembly with #{lomellina_users.size} members ---"

# =============================================================================
# PHASE 4: COMPONENTS FOR PROCESSES
# =============================================================================
puts "\n--- Phase 4: Adding Components to Processes ---"

lomellina_components = {}

lomellina_processes.each do |slug, process|
  puts "\nAdding components to: #{process.title['en']}"
  
  # Ensure process has an active step
  active_step = process.steps.find_by(active: true) || process.steps.first
  unless active_step
    puts "  WARNING: No steps found for process #{slug}"
    next
  end
  
  # Create Proposals component
  proposals_component = Decidim::Component.find_or_initialize_by(
    participatory_space: process,
    manifest_name: "proposals"
  )
  
  if proposals_component.new_record?
    proposals_component.assign_attributes(
      name: { en: "Flood Risk Proposals", it: "Proposte Rischio Alluvionale" },
      published_at: Time.current,
      weight: 0,
      settings: {
        vote_limit: 10,
        proposal_length: 5000,
        proposal_answering_enabled: true,
        official_proposals_enabled: true,
        comments_enabled: true,
        attachments_allowed: true,
        collaborative_drafts_enabled: true
      },
      step_settings: {
        active_step.id.to_s => {
          votes_enabled: true,
          votes_blocked: false,
          creation_enabled: true,
          comments_enabled: true
        }
      }
    )
    proposals_component.save!
    puts "  Created Proposals component"
  else
    puts "  Proposals component already exists"
  end
  
  lomellina_components["#{slug}_proposals"] = proposals_component
  
  # Create Meetings component
  meetings_component = Decidim::Component.find_or_initialize_by(
    participatory_space: process,
    manifest_name: "meetings"
  )
  
  if meetings_component.new_record?
    meetings_component.assign_attributes(
      name: { en: "Stakeholder Meetings", it: "Incontri Stakeholder" },
      published_at: Time.current,
      weight: 1,
      settings: {
        comments_enabled: true,
        resources_permissions_enabled: true
      }
    )
    meetings_component.save!
    puts "  Created Meetings component"
  else
    puts "  Meetings component already exists"
  end
  
  lomellina_components["#{slug}_meetings"] = meetings_component
  
  # Create content blocks for the process homepage
  begin
    Decidim::ContentBlocksCreator.new(process).create_default!
    puts "  Created content blocks for process"
  rescue => e
    puts "  Content blocks may already exist: #{e.message}"
  end
end

puts "\n--- Phase 4 Complete: Added components to all processes ---"

# =============================================================================
# PHASE 5: SAMPLE CONTENT (PROPOSALS AND MEETINGS)
# =============================================================================
puts "\n--- Phase 5: Creating Sample Content ---"

# Sample proposals from different stakeholder groups
LOMELLINA_PROPOSALS = {
  "valutazione-misura-arginature" => [
    {
      title: { en: "Technical Assessment of Sesia River Levee System", it: "Valutazione Tecnica Sistema Arginale Fiume Sesia" },
      body: { en: "<p>Based on our hydraulic modeling analysis, we propose a comprehensive assessment of the Sesia River levee system. The current infrastructure shows signs of subsidence in three critical sections that require immediate attention.</p><h4>Key Recommendations</h4><ul><li>Geotechnical investigation of foundation stability</li><li>Hydrological analysis under climate change scenarios</li><li>Cost-benefit analysis of reinforcement options</li></ul>", it: "<p>Proposta di valutazione tecnica del sistema arginale del fiume Sesia.</p>" },
      author_category: :university
    },
    {
      title: { en: "Agricultural Land Impact Assessment for Levee Operations", it: "Valutazione Impatto Terreni Agricoli per Operazioni Arginali" },
      body: { en: "<p>As representatives of the agricultural community, we request a detailed impact assessment of proposed levee operations on productive rice paddies. Our preliminary analysis indicates that 450 hectares of prime agricultural land could be affected.</p><h4>Concerns</h4><ul><li>Temporary land loss during construction</li><li>Long-term effects on irrigation systems</li><li>Economic compensation mechanisms</li></ul>", it: "<p>Richiesta di valutazione dell'impatto delle operazioni arginali sui terreni agricoli.</p>" },
      author_category: :agricultural
    },
    {
      title: { en: "Emergency Response Protocol Integration", it: "Integrazione Protocolli di Risposta alle Emergenze" },
      body: { en: "<p>Civil Protection proposes integrating the levee operation protocols with existing emergency response frameworks. This ensures coordinated action during flood events and optimizes resource deployment.</p><h4>Protocol Elements</h4><ul><li>Early warning trigger thresholds</li><li>Evacuation route coordination</li><li>Inter-agency communication channels</li></ul>", it: "<p>Proposta di integrazione dei protocolli di emergenza con le operazioni arginali.</p>" },
      author_category: :civil_protection
    }
  ],
  "valutazione-delocalizzazione-popolazione" => [
    {
      title: { en: "Social Impact Assessment Framework for Relocation", it: "Framework di Valutazione dell'Impatto Sociale per la Ricollocazione" },
      body: { en: "<p>We propose a comprehensive social impact assessment framework that prioritizes the needs of elderly and vulnerable community members during any delocalization process.</p><h4>Key Considerations</h4><ul><li>Health and social services continuity</li><li>Community network preservation</li><li>Psychological support programs</li></ul>", it: "<p>Framework per la valutazione dell'impatto sociale della ricollocazione.</p>" },
      author_category: :citizen_collective
    },
    {
      title: { en: "Environmental Heritage Protection During Delocalization", it: "Protezione del Patrimonio Ambientale Durante la Delocalizzazione" },
      body: { en: "<p>The Ecomuseo proposes guidelines for protecting environmental and cultural heritage assets during population delocalization. Our region's unique landscape requires careful consideration in any relocation planning.</p><h4>Heritage Elements</h4><ul><li>Historic waterway infrastructure</li><li>Traditional agricultural landscapes</li><li>Biodiversity corridors</li></ul>", it: "<p>Linee guida per la protezione del patrimonio ambientale durante la delocalizzazione.</p>" },
      author_category: :ngo
    },
    {
      title: { en: "Business Continuity Framework for Affected Areas", it: "Framework di Continuità Aziendale per le Aree Interessate" },
      body: { en: "<p>Confcommercio presents a business continuity framework to ensure economic stability during and after population delocalization. Local businesses require clear timelines and support mechanisms.</p><h4>Support Measures</h4><ul><li>Relocation assistance for businesses</li><li>Supply chain adaptation support</li><li>Economic transition funding</li></ul>", it: "<p>Framework per garantire la continuità aziendale durante la delocalizzazione.</p>" },
      author_category: :trade_union
    }
  ]
}.freeze

# Create proposals
LOMELLINA_PROPOSALS.each do |process_slug, proposals_data|
  process = lomellina_processes[process_slug]
  next unless process
  
  proposals_component = lomellina_components["#{process_slug}_proposals"]
  next unless proposals_component
  
  puts "\nCreating proposals for: #{process.title['en']}"
  
  proposals_data.each do |proposal_data|
    author = lomellina_users[proposal_data[:author_category]]
    author_group = lomellina_groups[proposal_data[:author_category]]
    next unless author && author_group
    
    # Check if proposal already exists
    existing = Decidim::Proposals::Proposal.where(component: proposals_component)
                .select { |p| p.title.dig("en") == proposal_data[:title][:en] }
    
    if existing.any?
      puts "  Proposal already exists: #{proposal_data[:title][:en][0..50]}..."
      next
    end
    
    begin
      proposal = Decidim::Proposals::Proposal.new(
        component: proposals_component,
        title: proposal_data[:title],
        body: proposal_data[:body],
        published_at: Time.current
      )
      
      # Add the user group as coauthor (organizational proposal)
      proposal.add_coauthor(author_group) if proposal.respond_to?(:add_coauthor)
      proposal.save!
      
      puts "  Created proposal: #{proposal_data[:title][:en][0..50]}... (by #{author_group.name})"
    rescue => e
      puts "  ERROR creating proposal: #{e.message}"
    end
  end
end

# Sample meetings
LOMELLINA_MEETINGS = {
  "valutazione-misura-arginature" => [
    {
      title: { en: "Technical Expert Session: Hydraulic Modeling Review", it: "Sessione Tecnica: Revisione Modellazione Idraulica" },
      description: { en: "<p>Technical session to review hydraulic models for the Sesia River basin. University experts present findings, Civil Protection provides operational context, and stakeholders validate assumptions.</p>", it: "<p>Sessione tecnica per la revisione dei modelli idraulici del bacino del fiume Sesia.</p>" },
      location: { en: "Politecnico di Milano - Online via Teams", it: "Politecnico di Milano - Online via Teams" },
      address: "Online Meeting",
      start_time: 1.week.from_now.change(hour: 14, min: 0),
      end_time: 1.week.from_now.change(hour: 16, min: 0)
    },
    {
      title: { en: "Community Consultation: Agricultural Impacts", it: "Consultazione Comunitaria: Impatti Agricoli" },
      description: { en: "<p>Open consultation with agricultural stakeholders to discuss potential impacts of levee operations on farming activities. Representatives from Terra di Riso and local farmers present concerns and proposals.</p>", it: "<p>Consultazione aperta con gli stakeholder agricoli per discutere gli impatti potenziali delle operazioni arginali.</p>" },
      location: { en: "Mortara Town Hall - Conference Room", it: "Municipio di Mortara - Sala Conferenze" },
      address: "Piazza Martiri della Libertà, 1, 27036 Mortara PV",
      start_time: 2.weeks.from_now.change(hour: 17, min: 0),
      end_time: 2.weeks.from_now.change(hour: 19, min: 30)
    }
  ],
  "valutazione-delocalizzazione-popolazione" => [
    {
      title: { en: "Social Impact Workshop: Vulnerable Populations", it: "Workshop Impatto Sociale: Popolazioni Vulnerabili" },
      description: { en: "<p>Workshop focused on understanding and addressing the needs of vulnerable populations (elderly, disabled, low-income) in potential delocalization scenarios. Connessioni di Vita leads the discussion.</p>", it: "<p>Workshop focalizzato sulla comprensione e gestione dei bisogni delle popolazioni vulnerabili.</p>" },
      location: { en: "Vigevano Community Center", it: "Centro Comunitario Vigevano" },
      address: "Via Roma 45, 27029 Vigevano PV",
      start_time: 3.weeks.from_now.change(hour: 10, min: 0),
      end_time: 3.weeks.from_now.change(hour: 13, min: 0)
    }
  ]
}.freeze

# Create meetings
LOMELLINA_MEETINGS.each do |process_slug, meetings_data|
  process = lomellina_processes[process_slug]
  next unless process
  
  meetings_component = lomellina_components["#{process_slug}_meetings"]
  next unless meetings_component
  
  puts "\nCreating meetings for: #{process.title['en']}"
  
  meetings_data.each do |meeting_data|
    # Check if meeting already exists
    existing = Decidim::Meetings::Meeting.where(component: meetings_component)
                .select { |m| m.title.dig("en") == meeting_data[:title][:en] }
    
    if existing.any?
      puts "  Meeting already exists: #{meeting_data[:title][:en][0..50]}..."
      next
    end
    
    begin
      meeting = Decidim::Meetings::Meeting.new(
        component: meetings_component,
        title: meeting_data[:title],
        description: meeting_data[:description],
        location: meeting_data[:location],
        location_hints: { en: "Please arrive 10 minutes early", it: "Si prega di arrivare 10 minuti prima" },
        address: meeting_data[:address],
        start_time: meeting_data[:start_time],
        end_time: meeting_data[:end_time],
        registration_terms: { en: "I agree to participate constructively.", it: "Accetto di partecipare costruttivamente." },
        registrations_enabled: true,
        available_slots: 50,
        private_meeting: false,
        transparent: true,
        published_at: Time.current
      )
      
      # Set author/organizer
      meeting.author = organization if meeting.respond_to?(:author=)
      
      meeting.save!
      puts "  Created meeting: #{meeting_data[:title][:en][0..50]}..."
    rescue => e
      puts "  ERROR creating meeting: #{e.message}"
    end
  end
end

puts "\n--- Phase 5 Complete: Created sample proposals and meetings ---"

# =============================================================================
# SUMMARY
# =============================================================================
puts "\n" + "=" * 70
puts "LOMELLINA FLOOD RISK SCENARIO - SEEDING COMPLETE"
puts "=" * 70
puts ""
puts "CREATED ENTITIES:"
puts "  - #{lomellina_users.size} stakeholder users (all confirmed, can login)"
puts "  - #{lomellina_groups.size} verified user groups"
puts "  - 1 Process Group: Gestione Rischio Idrogeologico Lomellina 2025"
puts "  - #{lomellina_processes.size} participatory processes (each with 3 phases)"
puts "  - 1 deliberative assembly with #{lomellina_users.size} members"
puts "  - Proposals, meetings, and components in all spaces"
puts ""
puts "-" * 70
puts "STAKEHOLDER LOGIN CREDENTIALS"
puts "-" * 70
puts "Password for ALL stakeholder users: Lomellina2024!Secure"
puts ""
LOMELLINA_STAKEHOLDERS.each do |s|
  puts "  #{s[:category].to_s.gsub('_', ' ').upcase}:"
  puts "    User:  #{s[:user_name]}"
  puts "    Email: #{s[:user_email]}"
  puts "    Group: #{s[:group_name]}"
  puts ""
end
puts "-" * 70
puts "KEY URLS (append to http://localhost:3000)"
puts "-" * 70
puts "  Process Group:     /processes_groups/1"
puts "  Assembly:          /assemblies/lomellina-flood-risk-assembly"
puts "  Assembly Members:  /assemblies/lomellina-flood-risk-assembly/members"
puts "  Assembly Proposals:/assemblies/lomellina-flood-risk-assembly/f/#{Decidim::Component.find_by(participatory_space: assembly, manifest_name: 'proposals')&.id}/proposals"
puts "  Levee Process:     /processes/valutazione-misura-arginature"
puts "  Delocalization:    /processes/valutazione-delocalizzazione-popolazione"
puts ""
puts "=" * 70
puts "Ready for Lomellina Flood Risk Use Case demonstration!"
puts "=" * 70

end # End of main if organization && admin block
