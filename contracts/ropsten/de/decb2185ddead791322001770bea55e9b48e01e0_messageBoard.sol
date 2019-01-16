contract messageBoard {
    string public message;
    // int public num = 129;
    int public people = 0;
    function messageBoard(string initMessage) public {
        message = initMessage;
    }
    function editMessage(string _editMessage) public {
        message = _editMessage;
    }
    function showMessage() public view{
        message = &#39;abcd&#39;;
    }
    function pay() public payable {
        people++;
    }
}