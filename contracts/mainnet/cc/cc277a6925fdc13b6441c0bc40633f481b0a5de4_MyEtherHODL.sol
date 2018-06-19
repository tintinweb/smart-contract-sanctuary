pragma solidity ^0.4.18;

//import &#39;zeppelin-solidity/contracts/ownership/Ownable.sol&#39;;
//import &#39;zeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol&#39;;


contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract MyEtherHODL is Ownable {

    event Hodl(address indexed hodler, uint indexed amount, uint untilTime, uint duration);
    event Party(address indexed hodler, uint indexed amount, uint duration);
    event Fee(address indexed hodler, uint indexed amount, uint elapsed);

    address[] public hodlers;
    mapping(address => uint) public indexOfHodler; // Starts from 1
    mapping (address => uint) public balanceOf;
    mapping (address => uint) public lockedUntil;
    mapping (address => uint) public lockedFor;

    function get1(uint index) public constant 
        returns(address hodler1, uint balance1, uint lockedUntil1, uint lockedFor1)
    {
        hodler1 = hodlers[index];
        balance1 = balanceOf[hodler1];
        lockedUntil1 = lockedUntil[hodler1];
        lockedFor1 = lockedFor[hodler1];
    }

    function get2(uint index) public constant 
        returns(address hodler1, uint balance1, uint lockedUntil1, uint lockedFor1,
                address hodler2, uint balance2, uint lockedUntil2, uint lockedFor2)
    {
        hodler1 = hodlers[index];
        balance1 = balanceOf[hodler1];
        lockedUntil1 = lockedUntil[hodler1];
        lockedFor1 = lockedFor[hodler1];

        hodler2 = hodlers[index + 1];
        balance2 = balanceOf[hodler2];
        lockedUntil2 = lockedUntil[hodler2];
        lockedFor2 = lockedFor[hodler2];
    }

    function get3(uint index) public constant 
        returns(address hodler1, uint balance1, uint lockedUntil1, uint lockedFor1,
                address hodler2, uint balance2, uint lockedUntil2, uint lockedFor2,
                address hodler3, uint balance3, uint lockedUntil3, uint lockedFor3)
    {
        hodler1 = hodlers[index];
        balance1 = balanceOf[hodler1];
        lockedUntil1 = lockedUntil[hodler1];
        lockedFor1 = lockedFor[hodler1];

        hodler2 = hodlers[index + 1];
        balance2 = balanceOf[hodler2];
        lockedUntil2 = lockedUntil[hodler2];
        lockedFor2 = lockedFor[hodler2];

        hodler3 = hodlers[index + 2];
        balance3 = balanceOf[hodler3];
        lockedUntil3 = lockedUntil[hodler3];
        lockedFor3 = lockedFor[hodler3];
    }
    
    function hodlersCount() public constant returns(uint) {
        return hodlers.length;
    }

    function() public payable {
        if (balanceOf[msg.sender] > 0) {
            hodlFor(0); // Do not extend time-lock
        } else {
            hodlFor(1 years);
        }
    }

    function hodlFor1y() public payable {
        hodlFor(1 years);
    }

    function hodlFor2y() public payable {
        hodlFor(2 years);
    }

    function hodlFor3y() public payable {
        hodlFor(3 years);
    }

    function hodlFor(uint duration) internal {
        if (indexOfHodler[msg.sender] == 0) {
            hodlers.push(msg.sender);
            indexOfHodler[msg.sender] = hodlers.length; // Store incremented value
        }
        balanceOf[msg.sender] += msg.value;
        if (duration > 0) { // Extend time-lock if needed only
            require(lockedUntil[msg.sender] < now + duration);
            lockedUntil[msg.sender] = now + duration;
            lockedFor[msg.sender] = duration;
        }
        Hodl(msg.sender, msg.value, lockedUntil[msg.sender], lockedFor[msg.sender]);
    }

    function party() public {
        partyTo(msg.sender);
    }

    function partyTo(address hodler) public {
        uint value = balanceOf[hodler];
        require(value > 0);
        balanceOf[hodler] = 0;

        if (now < lockedUntil[hodler]) {
            require(msg.sender == hodler);
            uint fee = value * 5 / 100;
            owner.transfer(fee);
            value -= fee;
            Fee(hodler, fee, lockedUntil[hodler] - now);
        }
        
        hodler.transfer(value);
        Party(hodler, value, lockedFor[hodler]);

        uint index = indexOfHodler[hodler];
        require(index > 0);
        if (hodlers.length > 1) {
            hodlers[index - 1] = hodlers[hodlers.length - 1];
            indexOfHodler[hodlers[index - 1]] = index;
        }
        hodlers.length--;

        delete balanceOf[hodler];
        delete lockedUntil[hodler];
        delete lockedFor[hodler];
        delete indexOfHodler[hodler];
    }

    // From zeppelin-solidity CanReclaimToken.sol
    function reclaimToken(ERC20Basic token) external onlyOwner {
        uint256 balance = token.balanceOf(this);
        token.transfer(owner, balance);
    }

}