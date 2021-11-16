/**
 *Submitted for verification at Etherscan.io on 2021-11-16
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
  string[] off_chain_data_hash;
  uint256 proposal_date;
  uint256 start_date;
  uint256 end_date;
  Status status;
}

contract BCoinProject {

  // Armazena o ID a ser utilizado na criacao do proximo projeto
  uint256 private _next_ID = 0;

  // Mapping ID to projects
  mapping(uint256 => Project) projects;

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

  function getContractBalance() public view returns (uint256 ){
    return address(this).balance;
  }

  function getLastID() public view returns (uint256 ){
    return _next_ID - 1;
  }
}