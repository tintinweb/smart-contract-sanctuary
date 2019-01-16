pragma solidity ^0.4.24;
contract BlogsLomeli {

    address public owner;
    uint256 public contador;
    
    struct Notas{
        uint256 id;
        uint256 date;
        string titulo;
        string descripcion;
    }
    mapping (uint256 => Notas) public notas;
    
	modifier onlyOwner {
		require(owner == msg.sender);
        _;
	}

	constructor() public{
		owner = msg.sender;
	}

	function createNota(string _titulo , string _description) onlyOwner public{
		notas[contador].id = contador;
		notas[contador].titulo = _titulo;
		notas[contador].descripcion = _description;
		notas[contador].date = now;
		emit logCreateNota(contador , now , _titulo , _description);
		contador++;
	}

	function updateNota(uint256 _code , string _titulo , string _description) onlyOwner public{
		notas[_code].titulo = _titulo;
		notas[_code].descripcion = _description;
		notas[_code].date = now;
		emit logUpdateNota(_code , now , _titulo , _description);
	}

	function deleteNota(uint256 _code) onlyOwner public{
		delete notas[_code];
		emit logDeleteNota(_code , now);
	}

	function getNota(uint256 _code) constant public returns(uint256 id , string titulo , string descripcion , uint256 date){
		Notas memory p = notas[_code];
		return (p.id, p.titulo, p.descripcion, p.date);
	}

	event logCreateNota(uint256 indexed _id, uint256 indexed _date, string _titulo, string _description);
	event logUpdateNota(uint256 indexed _id, uint256 indexed _date, string _titulo, string _description);
	event logDeleteNota(uint256 indexed _id, uint256 indexed _date);
}