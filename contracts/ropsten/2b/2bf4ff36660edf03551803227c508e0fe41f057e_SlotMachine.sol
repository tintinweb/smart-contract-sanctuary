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

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner!=address(0));
        owner = newOwner;
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
    }
    
    /**
     * Fallback function
     *
     * The function without name is the default function that is called whenever anyone sends funds to a contract
     */
    function() payable public {
        address from = msg.sender;
        uint256 value = msg.value;
        uint256 lowest = 1e16;
        require(from != 0x0);
        require(value >= lowest);
        
        uint count = value / lowest;
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
    function roulette(uint count) private view returns(bool,uint256[]) {
        uint256[] memory randoms = new uint256[](count);
        
        for(uint i = 0; i< count; i++){
            uint256 rand = uint256(keccak256(abi.encodePacked(now, msg.sender, i))) % 100;
            randoms[i] = rand;
            if(rand == 88) {
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