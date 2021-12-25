/**
 *Submitted for verification at Etherscan.io on 2021-12-25
*/

contract SCTF{

    mapping (address => uint256) public _balances;
    mapping (address => mapping(address => uint256)) public _approved;
    mapping (address => bool) public IsAirDrop;
    mapping (address => uint) public _loan;

    string public name = "Capture The Flag";
    string public symbol = "CTF";
    uint8 public decimals = 18;
    address public owner;
    uint256 public totalSupply=2021 * 1e18;
    uint256 public _loanpercentage=110;
    bool public success;

    event OwnerExchanged(address indexed previousOwner, address indexed newOwner);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed from, address indexed to, uint256 value);

    constructor() public {
        owner  = address(this);
        _balances[address(this)]=totalSupply;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "The caller must be owner");
        _;
    }

    function changeOwner(address newOwner) public onlyOwner returns(bool) {
        require(newOwner != address(0));
        emit OwnerExchanged(owner, newOwner);
        owner = newOwner;
        return true;
    }

    function transfer(address to, uint256 value) public returns (bool) {
        _balances[msg.sender] = _balances[msg.sender]-value;
        _balances[to] = _balances[to]+value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address to, uint256 value) public returns (bool) {
        _approved[msg.sender][to]=value;
        emit Approval(msg.sender, to, value);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public  returns (bool) {
        _approved[sender][msg.sender]-=amount;
        _balances[sender]-=amount;
        _balances[recipient]+=amount;
        emit Approval(sender,msg.sender,_approved[sender][msg.sender]);
        return true;
    }


    function mintforAirDrop(address to, uint256 number) public onlyOwner {
        require(!IsAirDrop[msg.sender],"You have got a this airDrop");
        require(to!=address(0),"Error address");
        _balances[to]+=number;
        emit Transfer(address(0), to, number);
    }

    function CallForAirDropmintor(bytes calldata _method) public {
        bytes memory returnData;
        bool success;
        (success, returnData) = address(this).call(abi.encodePacked(bytes4(keccak256(abi.encodePacked(_method, "(address,uint256)"))),abi.encode(msg.sender,uint(1e18))));
        require(success, "AirDrop failed");
    }



    function payforflag() public onlyOwner {
        success=true;
    }
    function isSolved() public returns(bool) {
        return success;
    }
}