pragma solidity ^0.5.0;

// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.0/contracts/token/ERC20/ERC20.sol";
import "ERC20.sol";
import "ERC20Detailed.sol";
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.0/contracts/token/ERC20/ERC20Detailed.sol";




contract YFE is ERC20, ERC20Detailed {
    address owner;
    using SafeMath for uint256;
    ERC20 public token;

    constructor () public ERC20Detailed("YFE Money", "YFE", 18) {
        _mint(msg.sender, 30000 * (10 ** uint256(decimals())));
        owner=msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }
}