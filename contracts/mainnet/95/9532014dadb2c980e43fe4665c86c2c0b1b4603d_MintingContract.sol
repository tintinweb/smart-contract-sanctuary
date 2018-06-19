contract SafeMath {
    
    uint256 constant public MAX_UINT256 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    function safeAdd(uint256 x, uint256 y) constant internal returns (uint256 z) {
        require(x <= MAX_UINT256 - y);
        return x + y;
    }

    function safeSub(uint256 x, uint256 y) constant internal returns (uint256 z) {
        require(x >= y);
        return x - y;
    }

    function safeMul(uint256 x, uint256 y) constant internal returns (uint256 z) {
        if (y == 0) {
            return 0;
        }
        require(x <= (MAX_UINT256 / y));
        return x * y;
    }
}

contract Owned {
    address public owner;
    address public newOwner;

    function Owned() {
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
        OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
    }

    event OwnerUpdate(address _prevOwner, address _newOwner);
}


contract Lockable is Owned {

    uint256 public lockedUntilBlock;

    event ContractLocked(uint256 _untilBlock, string _reason);

    modifier lockAffected {
        require(block.number > lockedUntilBlock);
        _;
    }

    function lockFromSelf(uint256 _untilBlock, string _reason) internal {
        lockedUntilBlock = _untilBlock;
        ContractLocked(_untilBlock, _reason);
    }


    function lockUntil(uint256 _untilBlock, string _reason) onlyOwner public {
        lockedUntilBlock = _untilBlock;
        ContractLocked(_untilBlock, _reason);
    }
}


contract ERC20PrivateInterface {
    uint256 supply;
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowances;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract tokenRecipientInterface {
  function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData);
}

contract OwnedInterface {
    address public owner;
    address public newOwner;

    modifier onlyOwner {
        _;
    }
}

contract ERC20TokenInterface {
  function totalSupply() public constant returns (uint256 _totalSupply);
  function balanceOf(address _owner) public constant returns (uint256 balance);
  function transfer(address _to, uint256 _value) public returns (bool success);
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
  function approve(address _spender, uint256 _value) public returns (bool success);
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}



contract MintableTokenInterface {
    function mint(address _to, uint256 _amount) public;
}

contract MintingContract is Owned {
    
    address public tokenAddress;
    enum state { crowdsaleMinintg, teamMinting, finished}

    state public mintingState; 
    uint public crowdsaleMintingCap;
    uint public tokensAlreadyMinted;
    
    uint public teamTokensPercent;
    address public teamTokenAddress;
    uint public communityTokens;
    uint public communityTokens2;
    address public communityAddress;
    
    constructor() public {
        crowdsaleMintingCap = 570500000 * 10**18;
        teamTokensPercent = 27;
        teamTokenAddress = 0xc2180bC387B7944FabE5E5e25BFaC69Af2Dc888A;
        communityTokens = 24450000 * 10**18;
        communityTokens2 = 5705000 * 10**18;
        communityAddress = 0x4FAAc921781122AA61cfE59841A7669840821b86;
    }
    
    function doCrowdsaleMinting(address _destination, uint _tokensToMint) onlyOwner public {
        require(mintingState == state.crowdsaleMinintg);
        require(tokensAlreadyMinted + _tokensToMint <= crowdsaleMintingCap);
        MintableTokenInterface(tokenAddress).mint(_destination, _tokensToMint);
        tokensAlreadyMinted += _tokensToMint;
    }
    
    function finishCrowdsaleMinting() onlyOwner public {
        mintingState = state.teamMinting;
    }
    
    function doTeamMinting() public {
        require(mintingState == state.teamMinting);
        uint onePercent = tokensAlreadyMinted/70;
        MintableTokenInterface(tokenAddress).mint(communityAddress, communityTokens2);
        MintableTokenInterface(tokenAddress).mint(teamTokenAddress, communityTokens - communityTokens2);
        MintableTokenInterface(tokenAddress).mint(teamTokenAddress, (teamTokensPercent * onePercent));
        mintingState = state.finished;
    }

    function setTokenAddress(address _tokenAddress) onlyOwner public {
        tokenAddress = _tokenAddress;
    }
}