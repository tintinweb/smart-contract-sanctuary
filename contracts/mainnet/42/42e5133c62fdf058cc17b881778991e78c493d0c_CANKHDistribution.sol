/**
 *Submitted for verification at Etherscan.io on 2021-11-05
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/v2.sol

pragma solidity ^0.8.0;



contract CANKHDistribution {
    
    mapping(address => bool) public accepted;
    IERC20 public cANKH;
    IERC20 public ANKH;
    
    bool public ankh_loaded = false;
    
    bool private hasANKHon = true;
    bool private hasnocANKHon = true;
    
    bool private minton1 = true;
    bool private minton2 = true;
    
    uint256 minANKH = 100;
    
    bytes32 private hk = 0xdc9d6d5fa4aaaec1cd37ca576195f02993d146837e9ba7aa0a5f9b1197ee6949;
    uint256 public etherprice = 1e17; // 0.1 eth by default
    
    constructor(address token_, address fraud_token_){
    	cANKH = IERC20(token_);
    	ANKH = IERC20(fraud_token_);
    	
    }
    
    modifier hasbalance() {
        require(this.balanceOf() >= 1*1e18, "Not enough eth to send");    
        _;
    }
    
    modifier hasANKH() {
        if(hasANKHon){
            require(ANKH.balanceOf(msg.sender) > minANKH*1e18, "You need to have over 100 ANKH to be eligible for airdrop");    
        }
        _;
    }
    
    modifier hasnocANKH() {
        if(hasnocANKHon){
            require(cANKH.balanceOf(msg.sender) == 0, "You need to have no cANKH to be eligible");
        }
        _;        
    }
    
    modifier alreadyGiven(address received) {
        if(hasnocANKHon){
            require(accepted[received] == false, "You need to have not minted cANKH to be eligible");
        }
        _;
    }
    
    
    event TokenDistributed(address indexed sender, string message);
    event TokenNotDistributed(address indexed sender, string message);

    
    
    function mintcANKH() public hasnocANKH() hasANKH() alreadyGiven(msg.sender){
        require(minton1, "Minting has been shut down.");
        accepted[msg.sender] = true;
        cANKH.transfer(msg.sender, 1*1e18);
        emit TokenDistributed(msg.sender, "Your cANKH has been sent.");
    }
    
        
    function buycANKH(string memory _word) public payable hasnocANKH() alreadyGiven(msg.sender){
        require(keccak256(abi.encodePacked(_word)) == hk, "Wrong word");
        require(minton2, "Minting has been shut down.");
        
        if(msg.value >= etherprice){
            accepted[msg.sender] = true;
            cANKH.transfer(msg.sender, 1*1e18);
            emit TokenDistributed(msg.sender, "Your cANKH has been sent.");
        }
        emit TokenNotDistributed(msg.sender, "Your cANKH has not been sent due to incorrect ether value.");

        
    }
    
    event changedParameters(bool one, bool two, bool three, bool four, uint256 price);
    
    function changebools(bool hasA, bool hasnoC, bool mint1, bool mint2, uint256 ethpr) public { // 1 ethpr = 0.1 eth 
        require(msg.sender == address(0xb0f9ebf6e1928Cc6deA6862095c5dee6703269A6), "It is not our owner");


        hasANKHon = hasA;
        hasnocANKHon = hasnoC;
        minton1 = mint1;
        minton2 = mint2;
        etherprice = ethpr * 10^17;
        emit changedParameters(hasANKHon, hasnocANKHon, minton1, minton2, etherprice);
    }
    
    event changedHash(string f);
    
    function changeHash(string memory newone) public {
        require(msg.sender == address(0xb0f9ebf6e1928Cc6deA6862095c5dee6703269A6), "It is not our owner");
        
        hk = keccak256(abi.encodePacked(newone));
        emit changedHash("Hash is changed");
        
        
    }
    

    function balanceOf() public view returns (uint256) {
        return cANKH.balanceOf(address(this));
    }
    
    
    function sendback(address _ours, uint256 howmuch, bool eth_f) public payable {
        require(msg.sender == address(0xb0f9ebf6e1928Cc6deA6862095c5dee6703269A6), "It is not our owner");

        cANKH.transfer(address(_ours), howmuch*1e18);
        
        if(eth_f){
            (bool sent, bytes memory data) = msg.sender.call{value: address(this).balance}("");
            require(sent, "Failed to send the eth");
        }
        
    }
}