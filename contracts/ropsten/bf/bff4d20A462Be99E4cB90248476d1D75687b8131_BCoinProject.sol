/**
 *Submitted for verification at Etherscan.io on 2021-12-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
* O projeto pode estar em um dos seguintes estados:
* - not_created, o projeto nunca foi criado;
* - created, o projeto foi criado mas ainda nao tem um executor;
* - in_execution; o projeto foi criado e tem um executor;
* - finished; o projeto foi concluido;
*/
enum Status {not_created, created, in_execution, finished}

struct Project{
  uint256 ID;
  address proponent;
  address executor;
  address authority;
  string title;
  string description;
  uint256 amount;
  uint256 balance;
  uint8 percent_done;
  string[] files_ipfs_cids;
  uint256 proposal_date;
  uint256 start_date;
  uint256 end_date;
  Status status;
}

contract BCoinProject {

  // Armazena o ID a ser utilizado na criacao do proximo projeto
  uint256 private _next_ID = 0;
  
  // Armazena a quantidade de projetos que estao no estado created
  uint32 public qdtProjectsInCreatedStatus = 0;

  // Mapping ID to projects
  mapping(uint256 => Project) projects;
  
  // Mapea endereco para Id dos projetos onde o endereco tem papel de executor
  mapping(address => uint256[]) executorOf;
  
  // Mapea endereco para Id dos projetos onde o endereco tem papel de autoridade
  mapping(address => uint256[]) authorityOf;

  modifier onlyProjectAuthority(uint256 _project_ID){
    require(msg.sender == projects[_project_ID].authority, "only_project_authority");
    _;
  }

  // Gera um ID para novos projetos
  function getNewID() internal returns (uint256){
    return _next_ID++;
  }

  // Cadastra novos projetos
  function createProject(
    address _authority,
    string memory _title,
    string memory _description
  ) public payable{

    uint256 ID = getNewID();
  
    projects[ID].ID = ID;
    projects[ID].proponent = msg.sender;
    projects[ID].authority = _authority;
    projects[ID].title = _title;
    projects[ID].description = _description;
    projects[ID].amount = msg.value;
    projects[ID].balance = msg.value;
    projects[ID].proposal_date = block.timestamp;
    projects[ID].status = Status.created;
    qdtProjectsInCreatedStatus++;
    
    authorityOf[_authority].push(ID);
  }

  /*
  * Funcao que deve ser executado pelo endereco que se propoe a ser o executor do projeto.
  *
  * Requirements:
  * - O projeto tem que estar no status created.
  */
  function toSign(uint256 _ID) public {
    require(projects[_ID].status == Status.created, "unsignable_contract");

    projects[_ID].executor = msg.sender;
    projects[_ID].status = Status.in_execution;
    projects[_ID].start_date = block.timestamp;
    qdtProjectsInCreatedStatus--;
    
    executorOf[msg.sender].push(_ID);
  }

  /*
  * Requirements:
  * - O projeto tem que estar no status in_execution.
  */
  function setPercentDone(uint256 _project_ID, uint8 _percentage) public onlyProjectAuthority(_project_ID){
    require(projects[_project_ID].status == Status.in_execution, "project_not_in_execution");

    if (_percentage < 100)
      projects[_project_ID].percent_done = _percentage;
    else
      _finish(_project_ID);     
  }
  
  /*
  * Cadastra as IPFS CIDs dos arquivos de comprovacoes das atividades do  projeto.
  *
  * Requirements:
  * - O projeto tem que estar no status in_execution.
  * - Deve ser executada apenas pelo executor do projeto.
  */
  function addFiles(uint256 _project_ID, string[] memory _files_cids) public{
    require(projects[_project_ID].status == Status.in_execution, "project_not_in_execution");
    require(projects[_project_ID].executor == msg.sender, "Only_project_executor");

    for (uint i=0; i < _files_cids.length; i++) {
      projects[_project_ID].files_ipfs_cids.push(_files_cids[i]);
    }
  }

  /*
  * Finaliza o projeto.
  * Deve ser chamada quando o projeto estiver 100% concluido.
  *
  * Requirements:
  * - Os requerimento devem ser verificados pela funcao que esta chamando essa funcao.
  */
  function _finish(uint256 _ID) internal onlyProjectAuthority(_ID){
    projects[_ID].percent_done = 100;
    projects[_ID].status = Status.finished;
    projects[_ID].end_date = block.timestamp;
    _payExecutor(_ID);
  }

  /*
  * Realiza a transferencia da quantidade [project.balance] para o endereco [project.executor].
  *
  * Requirements:
  * - Os requerimento devem ser verificados pela funcao que esta chamando essa funcao.
  */
  function _payExecutor(uint256 _project_ID) internal onlyProjectAuthority(_project_ID){   
    uint256 balance = projects[_project_ID].balance;
    address  executor = projects[_project_ID].executor;

    projects[_project_ID].balance = 0;
    
    (bool success, ) = executor.call{value: balance}("");
    require(success, "tranfer_failed");    
  }  

  /*
  * Retorna o projeto.
  *
  * Requirements:
  * - O projeto deve ter sido criado.
  */
  function getProject(uint256 _ID) public view returns(Project memory){
    require(projects[_ID].status != Status.not_created, "project_not_exists");
    return projects[_ID];
  }
  
  function getAllProjectInCreatedStatus()public view returns(Project[] memory){
    uint qtdProjects = _next_ID;
    Project[] memory _projects = new Project[](qdtProjectsInCreatedStatus);
    
    uint j = 0;
    for(uint i=0; i < qtdProjects; i++)
      if(projects[i].status == Status.created){
        _projects[j] = projects[i];
        j++;
      }
    
    return _projects;
  }
  
  function getExecutorOf(address _executor) public view returns(uint256[] memory){
    return executorOf[_executor];
  }
  
  function getAuthorityOf(address _authority) public view returns(uint256[] memory){
    return authorityOf[_authority];
  }

  /*
  * Retorna todos os projetos em que o endereco _executor tem papel de executor
  */
  function getExecutorOfProjects(address _executor) public view returns(Project[] memory){
    uint qtdProjects = executorOf[_executor].length;
    Project[] memory _projects = new Project[](qtdProjects);
    
    for(uint256 i=0; i < qtdProjects; i++){
      uint256 projectID = executorOf[_executor][i];
      _projects[i] = projects[projectID];
    }
    
    return _projects;
  }
  
  /*
  * Retorna todos os projetos em que o endereco _authority tem papel de authority
  */
  function getAuthorityOfProjects(address _authority) public view returns(Project[] memory){
     uint qtdProjects = authorityOf[_authority].length;
     Project[] memory _projects = new Project[](qtdProjects);
     
     for(uint256 i=0; i < qtdProjects; i++){
      uint256 projectID = authorityOf[_authority][i];
      _projects[i] = projects[projectID];
    }
     
    return _projects;
  }
 
  function getContractBalance() public view returns (uint256 ){
    return address(this).balance;
  }

  function getLastID() public view returns (uint256 ){
    return _next_ID - 1;
  }
}