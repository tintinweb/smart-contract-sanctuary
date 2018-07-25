pragma solidity ^0.4.24;

contract VarangardBlog2 {

    address public owner;
    uint256 public contador;
    
    struct Posts {
        uint256 id;
        uint256 date;
        string titulo;
        string descripcion;
    }
    mapping (uint256 => Posts) public post;
    
    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function createPost(string _titulo, string _description) onlyOwner public {
        post[contador].id = contador;
        post[contador].titulo = _titulo;
        post[contador].descripcion = _description;
        post[contador].date = block.timestamp;
        emit logNewNote(contador, block.timestamp, _titulo, _description);
        contador++;
    }

    function updatePost(uint256 _code, string _titulo, string _description) onlyOwner public {
        post[_code].titulo = _titulo;
        post[_code].descripcion = _description;
        post[_code].date = block.timestamp;
        emit logUpdateNote(_code, block.timestamp, _titulo, _description);
    }

    function deletePost(uint256 _code) onlyOwner public{
        delete post[_code];
        emit logDeleteNote(_code, block.timestamp);
    }

    function getPost(uint256 _code) constant public returns(uint256 id, string titulo, string descripcion, uint256 date) {
        Posts memory p = post[_code];
        return (p.id, p.titulo, p.descripcion, p.date);
    }

    event logNewNote(uint256 indexed _id, uint256  _date, string indexed _titulo, string indexed _description);
    event logUpdateNote(uint256 indexed _id, uint256  _date, string indexed _titulo, string indexed _description);
    event logDeleteNote(uint256 indexed _id, uint256  _date);
}