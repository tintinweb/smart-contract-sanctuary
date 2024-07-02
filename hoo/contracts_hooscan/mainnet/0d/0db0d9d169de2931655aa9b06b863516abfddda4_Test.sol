/**
 *Submitted for verification at hooscan.com on 2021-08-31
*/

contract Test {

    address public _owner;

    string public _symbol;

    string public _name;

    constructor() public {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
    function initialize(string memory name, string memory symbol) public onlyOwner {
        _name = name;
        _symbol = symbol;
    }
    
}