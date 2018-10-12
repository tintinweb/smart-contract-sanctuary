pragma solidity ^0.4.25;

contract Owned {
    address public owner;
    address public newOwner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        assert(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
    }

    event OwnerUpdate(address _prevOwner, address _newOwner);
}

contract SafeMath {
    
    uint256 constant public MAX_UINT256 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    function safeAdd(uint256 x, uint256 y) pure internal returns (uint256 z) {
        require(x <= MAX_UINT256 - y);
        return x + y;
    }

    function safeSub(uint256 x, uint256 y) pure internal returns (uint256 z) {
        require(x >= y);
        return x - y;
    }

    function safeMul(uint256 x, uint256 y) pure internal returns (uint256 z) {
        if (y == 0) {
            return 0;
        }
        require(x <= (MAX_UINT256 / y));
        return x * y;
    }
}

interface MintableTokenInterface {
    function mint(address _to, uint256 _amount) external;
}

contract MintingContract is Owned, SafeMath{
    
    address public tokenAddress;
    uint256 public tokensAlreadyMinted;

    enum state { crowdsaleMinting, additionalMinting, disabled}
    state public mintingState; 

    uint256 public crowdsaleMintingCap;
    uint256 public tokenTotalSupply;
    
    constructor() public {
        tokensAlreadyMinted = 0;
        crowdsaleMintingCap = 22000000 * 10 ** 18;
        tokenTotalSupply = 44000000 * 10 ** 18;
    }

    function doCrowdsaleMinting(address _destination, uint _tokensToMint) public onlyOwner {
        require(mintingState == state.crowdsaleMinting);
        require(safeAdd(tokensAlreadyMinted, _tokensToMint) <= crowdsaleMintingCap);

        MintableTokenInterface(tokenAddress).mint(_destination, _tokensToMint);
        tokensAlreadyMinted = safeAdd(tokensAlreadyMinted, _tokensToMint);
    }
    function doAdditionalMinting(address _destination, uint _tokensToMint) public {
        require(mintingState == state.additionalMinting);
        require(safeAdd(tokensAlreadyMinted, _tokensToMint) <= tokenTotalSupply);

        MintableTokenInterface(tokenAddress).mint(_destination, _tokensToMint);
        tokensAlreadyMinted = safeAdd(tokensAlreadyMinted, _tokensToMint);
    }
    
    function finishCrowdsaleMinting() onlyOwner public {
        mintingState = state.additionalMinting;
    }
    
    function disableMinting() onlyOwner public {
        mintingState = state.disabled;
    }

    function setTokenAddress(address _tokenAddress) onlyOwner public {
        tokenAddress = _tokenAddress;
    }
    
 
}