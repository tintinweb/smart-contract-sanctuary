pragma solidity ^0.5.2;

contract owned {

    address owner;

    /*this function is executed at initialization and sets the owner of the contract */
    constructor() public { owner = msg.sender; }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

contract mortal is owned {

    /* Function to recover the funds on the contract */
    function kill() public onlyOwner() {
        selfdestruct(msg.sender);
    }

}

contract ChainLife is owned, mortal {
    
    Flight[] public fligts;
    Movie[] public movies;
    Book[] public books;
    
    struct Flight {
        bytes3 from;
        bytes3 to;
        bytes10 date;
        int8 duration;
    }
    
     struct Movie {
         string name;
         int8 rating;
     }
     
     struct Book {
         string title;
         string author;
         bytes13 ISBN;
         
     }
    
    constructor() public {
        owner = msg.sender;
    }
    
    function addFlight(bytes3 _from, bytes3 _to, bytes10 _date, int8 _duration) public onlyOwner() {
        Flight memory element = Flight(_from, _to, _date, _duration);
        fligts.push(element);
    }
    
    function addMovie(string memory _name, int8 _rating) public onlyOwner() {
        Movie memory element = Movie(_name, _rating);
        movies.push(element);
    }
    
    function addBook(string memory _title, string memory _author, bytes13 _ISBN) public onlyOwner() {
        Book memory element = Book(_title, _author, _ISBN);
        books.push(element);
    }    
    
    function getFlight(uint8 id) view public returns (bytes3 _from, bytes3 _to, bytes10 _date, int8 _duration) {
        return (fligts[id].from, fligts[id].to, fligts[id].date, fligts[id].duration);
    }

    function getMovie(uint8 id) view public returns (string memory _name, int8 _rating) {
        return (movies[id].name, movies[id].rating); 
    }
    
    function getBook(uint8 id) view public returns (string memory _title, string memory _author, bytes13 _ISBN) {
        return (books[id].title, books[id].author, books[id].ISBN);
    }
}