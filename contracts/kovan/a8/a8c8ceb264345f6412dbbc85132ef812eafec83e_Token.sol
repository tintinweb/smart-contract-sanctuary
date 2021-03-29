pragma solidity 0.5.13;

import "./ERC20.sol";
import "./ERC20Detailed.sol";


/**
 * @title SimpleToken
 * @dev Very simple ERC20 Token example, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `ERC20` functions.
 */
contract Token is ERC20, ERC20Detailed {
    address public adm;

    uint8 public constant DECIMALS = 18;
    //uint256 public constant INITIAL_SUPPLY = 500000000 * (10 ** uint256(DECIMALS));

    bool public activeMint;
    address public brlUsdConsumerAddress;
    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor () public ERC20Detailed("BRL CRYPTO", "BRLX", DECIMALS) {
        activeMint = false;
        adm = msg.sender; 
    }

    modifier onlyOwner(){
        require(adm == msg.sender);
        _;
    }

    modifier onlyBrlUsdConsumer(){
        require(brlUsdConsumerAddress == msg.sender);
        _;
    }
    
    modifier onlyActiveMint(){
        require(activeMint == true);
        _;
    }

    function activeBrlUsdConsumer(address _contractAddress) public onlyOwner(){
        brlUsdConsumerAddress = _contractAddress;
        activeMint = true;
    }



    function mintFromDai(uint256 _amount, address _owner) public onlyActiveMint() onlyBrlUsdConsumer(){
        _mint(_owner, _amount);
        return;
    }
    
    
}