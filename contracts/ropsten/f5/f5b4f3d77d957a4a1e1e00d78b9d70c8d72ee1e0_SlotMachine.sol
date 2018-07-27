pragma solidity ^0.4.24;

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {

    address public owner;

    uint256 public contractPrice;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    
    function setContractPrice(uint256 price) public onlyOwner{
        contractPrice = price * 1e18;
    }
    

    function transferOwnership() payable public returns(bool){
        require(msg.value >= contractPrice);
        owner.transfer(msg.value);
        emit OwnershipTransferred(owner, msg.sender);
        owner = msg.sender;
        return true;
    }
}

contract SlotMachine is Ownable {
    
    using SafeMath for uint256;

    address public owner;
    
    event Roulette
    (
        address indexed from, 
        uint256 value,
        uint256[] randoms
    );
    
    constructor() payable public {
        owner = msg.sender;
        contractPrice = 999999e18;
    }
    
    /**
     * Fallback function
     *
     * The function without name is the default function that is called whenever anyone sends funds to a contract
     */
    function() payable public {
        address from = msg.sender;
        uint256 value = msg.value;
        require(from != 0x0);
        if(value < 1e17){
            return;
        }
        
        uint count = value / 1e16;
        bool result;
        uint256[] memory randoms;
        (result,randoms) = roulette(count);
        if(result){
            uint256 award = jackpot().div(2);
            uint256 tax = award.div(5);
            owner.transfer(tax);
            from.transfer(award.sub(tax));
            emit Roulette(from, value, randoms);
        }
    }
    
    
    /**
     * roulette
     */
    function roulette(uint count) public view returns(bool,uint256[]) {
        uint256[] memory randoms = new uint256[](count);
        
        uint256 rand = uint256(keccak256(abi.encodePacked(now, msg.sender)));
        for(uint i = 1; i< count + 1; i++){
            uint256 _rand = uint256(rand / (i * 33)) % 100;
            randoms[i] = _rand;
            if(_rand == 88) {
                return (true,randoms);
            }
        }
        return (false,randoms);
    }
    
    
    /**
     * Get jackpot
     */
    function jackpot() public view returns (uint256) {
        return address(this).balance;
    }
    
}