contract Simple {
    string public name = &#39;No name&#39;;
    
    function setName(string newName) public {
        name = newName;
    }
}