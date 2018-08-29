pragma solidity 0.4.23;

/**
 * Thank you to Zeppelin for the following SafeMath Library
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */


library SafeMath {
    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }
    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    /**
    * @dev Adds two numbers, throws on overflow.
    */
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


contract Token {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract Test2 {
    using SafeMath for uint;
    address admin;
    
    enum OptionState {
        BEFOREOPEN,
        BEFOREACTIVATED,
        DURINGOPEN,
        DURINGACTIVATED,
        DURINGCLOSED,
        AFTEROPEN,
        AFTERCLOSED,
        ADMIN
    }
    
    struct Option {
        mapping (address => mapping (address => uint)) sellerDepositBalance;
        mapping (address => mapping (address => uint)) sellerPremiumBalance;
        mapping (address => uint) contractBalance;
        uint premiumBalance;
        bool premiumDeposit;
        bool etherDeposit;
        bool tokenDeposit;
        address buyer;
    }
    
    mapping (bytes32 => Option) public optionRecord;
    
    event PremiumDeposited(
        address indexed bullAddress, 
        uint indexed premiumDepositedAmount, 
        uint premiumDepositedTotAmount, 
        bytes32 indexed optionHash
    );
    
    event TokenDeposited(
        address indexed bearAddress, 
        uint indexed tokenDepositedAmount, 
        uint tokenDepositedTotAmount, 
        bytes32 indexed optionHash
    );
    
    event BuyerWithdrawn(
        address indexed bullAddress, 
        uint indexed buyerWithdrawnAmount, 
        uint buyerWithdrawnTotAmount, 
        bytes32 indexed optionHash
    );
    
    event SellerWithdrawn(
        address indexed bearAddress, 
        uint indexed sellerWithdrawnAmount, 
        uint sellerWithdrawnTotAmount, 
        bytes32 indexed optionHash
    );
    
    event EtherDeposited(
        address indexed bullAddress, 
        uint indexed etherDepositedAmount, 
        uint etherDepositedTotAmount, 
        bytes32 indexed optionHash
    );
    
    event TokenBuyerClaimed(
        address indexed bearAddress, 
        uint etherClaimedAmount, 
        uint etherClaimedTotAmount, 
        bytes32 indexed optionHash
    );
    
    event PremiumClaimed(
        address indexed bullAddress, 
        uint indexed premiumClaimedAmount, 
        uint premiumClaimedTotAmount, 
        bytes32 indexed optionHash
    );
    
    event TokenClaimed(
        address indexed bullAddress, 
        uint indexed tokenClaimedAmount, 
        uint tokenClaimedTotAmount, 
        bytes32 indexed optionHash
    );
    
    event UnderlyingClaimed(
        address indexed bullAddress, 
        uint indexed underlyingClaimedAmount, 
        uint underlyingClaimedTotAmount, 
        bytes32 indexed optionHash
    );
    
    event StewardNowAdmin(
        address indexed stewardAddress, 
        uint indexed stewardNowAdminAmount, 
        bytes32 indexed optionHash
    );
    
    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }
    
    function kill() public onlyAdmin() {
        selfdestruct(admin);
    }
    
    constructor() public {
        admin = msg.sender;
    }
    
    function changeAdmin(address _admin) 
    external 
    onlyAdmin 
    {
        admin = _admin;
    }
    
    function getOptionState(address[2] tokenCreator, uint[7] tokenEthDMWCNonce)
    private
    view
    returns(OptionState)
    {
        bytes32 optionHash = returnHash(tokenCreator, tokenEthDMWCNonce);
        if (block.timestamp <= tokenEthDMWCNonce[2]) {
            if (
                !optionRecord[optionHash].premiumDeposit || 
                !optionRecord[optionHash].tokenDeposit) 
                return OptionState.BEFOREOPEN;
            else if (
                optionRecord[optionHash].premiumDeposit && 
                optionRecord[optionHash].tokenDeposit) 
                return OptionState.BEFOREACTIVATED;
        } else if (block.timestamp > tokenEthDMWCNonce[2] &&
        block.timestamp <= tokenEthDMWCNonce[3]) {
            if (
                optionRecord[optionHash].etherDeposit)
                return OptionState.DURINGCLOSED;
            else if (
                optionRecord[optionHash].premiumDeposit && 
                optionRecord[optionHash].tokenDeposit)
                return OptionState.DURINGACTIVATED;
            else if (
                !optionRecord[optionHash].premiumDeposit || 
                !optionRecord[optionHash].tokenDeposit) 
                return OptionState.DURINGOPEN;
        } else if (block.timestamp > tokenEthDMWCNonce[3] && 
        block.timestamp <= tokenEthDMWCNonce[4]) {
            if (
                !optionRecord[optionHash].premiumDeposit || 
                !optionRecord[optionHash].tokenDeposit) 
                return OptionState.AFTEROPEN;
            else if (
                optionRecord[optionHash].tokenDeposit || 
                optionRecord[optionHash].etherDeposit)
                return OptionState.AFTERCLOSED;
        } else if (block.timestamp > tokenEthDMWCNonce[4]) {
            return OptionState.ADMIN;
        } else {
            revert();
        }
    }
    
    function depositPremium(address[2] tokenCreator, uint[7] tokenEthDMWCNonce, uint8 v, bytes32[2] rs) 
    external 
    payable 
    {
        bytes32 optionHash = returnHash(tokenCreator, tokenEthDMWCNonce);
        address creator = ecrecover(keccak256("\x19Ethereum Signed Message:\n32", optionHash), v, rs[0], rs[1]);
        require(
            creator == tokenCreator[1] && 
            !optionRecord[optionHash].premiumDeposit &&
            msg.value == tokenEthDMWCNonce[5] &&
            getOptionState(tokenCreator, tokenEthDMWCNonce) == OptionState.BEFOREOPEN 
        );
        optionRecord[optionHash].buyer = msg.sender;
        optionRecord[optionHash].premiumBalance = optionRecord[optionHash].premiumBalance.add(msg.value);
        optionRecord[optionHash].premiumDeposit = true;
        emit PremiumDeposited(msg.sender, msg.value, optionRecord[optionHash].premiumBalance, optionHash);
    }
    
    function depositToken(address[2] tokenCreator, uint[7] tokenEthDMWCNonce, uint8 v, bytes32[2] rs) 
    external 
    payable 
    {
        bytes32 optionHash = returnHash(tokenCreator, tokenEthDMWCNonce);
        address creator = ecrecover(keccak256("\x19Ethereum Signed Message:\n32", optionHash), v, rs[0], rs[1]);
        require(
            creator == tokenCreator[1] && 
            Token(tokenCreator[0]).transferFrom(msg.sender, this, tokenEthDMWCNonce[0]) &&
            getOptionState(tokenCreator, tokenEthDMWCNonce) == OptionState.BEFOREOPEN
        );
        optionRecord[optionHash].contractBalance[tokenCreator[0]] = 
            optionRecord[optionHash].contractBalance[tokenCreator[0]].add(tokenEthDMWCNonce[0]);
        optionRecord[optionHash].sellerPremiumBalance[msg.sender][tokenCreator[0]] = tokenEthDMWCNonce[5];
        optionRecord[optionHash].tokenDeposit = true;
        emit TokenDeposited(msg.sender, msg.value, optionRecord[optionHash].contractBalance[0], optionHash);
    }
    
    function withdrawBuyer(address[2] tokenCreator, uint[7] tokenEthDMWCNonce, uint8 v, bytes32[2] rs) 
    external 
    {
        bytes32 optionHash = returnHash(tokenCreator, tokenEthDMWCNonce);
        address creator = ecrecover(keccak256("\x19Ethereum Signed Message:\n32", optionHash), v, rs[0], rs[1]);
        require(
            creator == tokenCreator[1] && 
            optionRecord[optionHash].buyer == msg.sender && 
            getOptionState(tokenCreator, tokenEthDMWCNonce) == OptionState.DURINGOPEN || 
            getOptionState(tokenCreator, tokenEthDMWCNonce) == OptionState.AFTEROPEN
        );
        uint premiumAmountDue = optionRecord[optionHash].premiumBalance;
        optionRecord[optionHash].premiumBalance = uint(0);
        msg.sender.transfer(premiumAmountDue);
        emit BuyerWithdrawn(msg.sender, premiumAmountDue, optionRecord[optionHash].premiumBalance, optionHash);
    }
    
    function withdrawSeller(address[2] tokenCreator, uint[7] tokenEthDMWCNonce, uint8 v, bytes32[2] rs) 
    external 
    {
        bytes32 optionHash = returnHash(tokenCreator, tokenEthDMWCNonce);
        address creator = ecrecover(keccak256("\x19Ethereum Signed Message:\n32", optionHash), v, rs[0], rs[1]);
        require(
            creator == tokenCreator[1] && 
            getOptionState(tokenCreator, tokenEthDMWCNonce) == OptionState.DURINGOPEN || 
            getOptionState(tokenCreator, tokenEthDMWCNonce) == OptionState.AFTEROPEN
        );
        require(Token(tokenCreator[0]).transfer(msg.sender, tokenEthDMWCNonce[0]));
        uint tokenAmount = tokenEthDMWCNonce[0];
        optionRecord[optionHash].contractBalance[tokenCreator[0]] = uint(0);
        emit SellerWithdrawn(msg.sender, tokenAmount, optionRecord[optionHash].contractBalance[0], optionHash);
    }
    
    function depositEther(address[2] tokenCreator, uint[7] tokenEthDMWCNonce, uint8 v, bytes32[2] rs) 
    external 
    {
        bytes32 optionHash = returnHash(tokenCreator, tokenEthDMWCNonce);
        address creator = ecrecover(keccak256("\x19Ethereum Signed Message:\n32", optionHash), v, rs[0], rs[1]);
        require(
            creator == tokenCreator[1] && 
            optionRecord[optionHash].buyer == msg.sender && 
            msg.value == tokenEthDMWCNonce[1] &&
            getOptionState(tokenCreator, tokenEthDMWCNonce) == OptionState.DURINGACTIVATED
        );
        optionRecord[optionHash].contractBalance[0] = 
            optionRecord[optionHash].contractBalance[0].add(tokenEthDMWCNonce[1]);
        uint buyerTokenBalance = optionRecord[optionHash].contractBalance[tokenCreator[0]];
        optionRecord[optionHash].contractBalance[tokenCreator[0]] = uint(0);
        optionRecord[optionHash].etherDeposit = true;
        require(Token(tokenCreator[0]).transfer(msg.sender, tokenEthDMWCNonce[0]));
        emit EtherDeposited(msg.sender, tokenEthDMWCNonce[0], optionRecord[optionHash].contractBalance[tokenCreator[0]], optionHash);
        emit TokenBuyerClaimed(msg.sender, buyerTokenBalance, optionRecord[optionHash].contractBalance[0], optionHash);
    }
    
    function claimPremium(address[2] tokenCreator, uint[7] tokenEthDMWCNonce, uint8 v, bytes32[2] rs) 
    external 
    {
        bytes32 optionHash = returnHash(tokenCreator, tokenEthDMWCNonce);
        address creator = ecrecover(keccak256("\x19Ethereum Signed Message:\n32", optionHash), v, rs[0], rs[1]);
        uint premiumAmount = tokenEthDMWCNonce[5];
        require(
            creator == tokenCreator[1] &&
            getOptionState(tokenCreator, tokenEthDMWCNonce) == OptionState.BEFOREACTIVATED || 
            getOptionState(tokenCreator, tokenEthDMWCNonce) == OptionState.DURINGACTIVATED || 
            getOptionState(tokenCreator, tokenEthDMWCNonce) == OptionState.DURINGCLOSED || 
            getOptionState(tokenCreator, tokenEthDMWCNonce) == OptionState.AFTERCLOSED
        );
        optionRecord[optionHash].sellerPremiumBalance[msg.sender][0] = uint(0);
        msg.sender.transfer(premiumAmount);
        emit PremiumClaimed(msg.sender, premiumAmount, optionRecord[optionHash].premiumBalance, optionHash);
    }
    
    function claimUnderlying(address[2] tokenCreator, uint[7] tokenEthDMWCNonce, uint8 v, bytes32[2] rs) 
    external
    {
        bytes32 optionHash = returnHash(tokenCreator, tokenEthDMWCNonce);
        address creator = ecrecover(keccak256("\x19Ethereum Signed Message:\n32", optionHash), v, rs[0], rs[1]);
        require(
            creator == tokenCreator[1] &&
            getOptionState(tokenCreator, tokenEthDMWCNonce) == OptionState.DURINGCLOSED || 
            getOptionState(tokenCreator, tokenEthDMWCNonce) == OptionState.AFTERCLOSED
        );
        optionRecord[optionHash].etherDeposit ? 
            settleToken(optionHash, tokenCreator[0], tokenEthDMWCNonce[1], tokenEthDMWCNonce[0]) : 
            settleETH(optionHash);
    }
    
    function settleToken(bytes32 optionHash, address tokenAddress, uint _ether, uint _token)
    private
    {
        uint tokenAmount = optionRecord[optionHash].contractBalance[tokenAddress];
        optionRecord[optionHash].contractBalance[tokenAddress] = uint(0);
        require(Token(tokenAddress).transfer(msg.sender, tokenAmount));
        emit TokenClaimed(msg.sender, tokenAmount, optionRecord[optionHash].contractBalance[tokenAddress], optionHash);
    }
    
    function settleETH(bytes32 optionHash)
    private 
    {
        uint _userBalance = optionRecord[optionHash].contractBalance[0]; 
        optionRecord[optionHash].contractBalance[0] = uint(0);      
        msg.sender.transfer(_userBalance);  
        emit UnderlyingClaimed(msg.sender, _userBalance, optionRecord[optionHash].contractBalance[0], optionHash);
    }
    
    function adminStewardship(address[2] tokenCreator, uint[7] tokenEthDMWCNonce, uint8 v, bytes32[2] rs) 
    external 
    onlyAdmin 
    {
        bytes32 optionHash = returnHash(tokenCreator, tokenEthDMWCNonce);
        address creator = ecrecover(keccak256("\x19Ethereum Signed Message:\n32", optionHash), v, rs[0], rs[1]);
        uint tokenAmount = optionRecord[optionHash].contractBalance[tokenCreator[0]];
        require(
            creator == tokenCreator[1] && 
            getOptionState(tokenCreator, tokenEthDMWCNonce) == OptionState.ADMIN &&
            Token(tokenCreator[0]).transfer(admin, tokenAmount)
        );
        uint ethAmount = optionRecord[optionHash].contractBalance[0];
        uint premiumBalance = optionRecord[optionHash].premiumBalance;
        admin.transfer(premiumBalance.add(ethAmount));
        emit StewardNowAdmin(msg.sender, premiumBalance.add(ethAmount), optionHash);
    }
    
    // Start of return functions (provide information queried by website)
    function returnCreatorAddress(bytes32 optionHash, uint8 v, bytes32[2] rs) 
    external 
    pure 
    returns (address) 
    {
        return ecrecover(optionHash, v, rs[0], rs[1]);
    }
    
    function returnHash(address[2] tokenCreator, uint[7] tokenEthDMWCNonce) 
    public
    pure 
    returns (bytes32) 
    {
        return
        keccak256(
            tokenCreator[0],
            tokenCreator[1],
            tokenEthDMWCNonce[0],
            tokenEthDMWCNonce[1],
            tokenEthDMWCNonce[2],
            tokenEthDMWCNonce[3],
            tokenEthDMWCNonce[4],
            tokenEthDMWCNonce[5],
            tokenEthDMWCNonce[6]
        );
    }
}