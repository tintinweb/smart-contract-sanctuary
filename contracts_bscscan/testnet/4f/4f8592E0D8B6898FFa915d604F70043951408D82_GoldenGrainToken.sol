// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;

import "./BEP20.sol";

// GrainToken
contract GoldenGrainToken is BEP20 {
    address public lpToken;
    address public _operator;

    // Burn address
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    
    bool private tradingOpen = false;

    // UFF MOD - ADD WHITELIST MAP
    mapping(address=>bool) isWhitelisted;

    // Operator CAN do modifier
    modifier onlyOperator() {
        require(_operator == msg.sender, "operator: caller is not the operator");
        _;
    }

    /**z
     * @notice Constructs the GOLDEN GRAIN token contract.
     */
    constructor() public BEP20("Golden Grain", "GGRAIN") {
        _operator = msg.sender;        
    }

    // UFF MOD - ADD ROUTER WHITELIST UTILS
    function whiteListRouter(address _token) public {
        require(_operator == msg.sender, 'GGRAIN: ONLY FEE TO SETTER');
        require(!isWhitelisted[_token], "GGRAIN: ALREADY WHITELISTED");
        isWhitelisted[_token] = true;
    }

    function removeFromWhiteList(address _token) public {
        require(_operator == msg.sender, 'GGRAIN: ONLY FEE TO SETTER');
        require(isWhitelisted[_token], "GGRAIN: ALREADY REMOVED FROM WHITELIST");
        isWhitelisted[_token] = false;
    }

    function whiteListed(address _token) public view returns (bool) {
        return isWhitelisted[_token];
    }

    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }

    /// @dev overrides transfer function to meet tokenomics of GOLDEN GRAIN
    function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
        // console.log("sender", sender);
        require(amount > 0, "Transfer amount must be greater than zero");

        if (isWhitelisted[sender] || sender == owner() || recipient == lpToken || sender == lpToken) {
            super._transfer(sender, recipient, amount);
        } else {
            require(tradingOpen == true, "GOLDEN GRAIN TRADING CLOSED");    
        }
    }

    /**
     * @dev Returns the address of the current operator.
     */
    function operator() public view returns (address) {
        return _operator;
    }

    // Return actual supply of rice
    function ggrainSupply() public view returns (uint256) {
        return totalSupply().sub(balanceOf(BURN_ADDRESS));
    }
    
    /**
     * @dev Open trading (PCS) onlyOperator
     */
    function openTrading() public onlyOperator {
        // Can open trading only once!
        require(tradingOpen != true, "GGRAIN: Trading not yet open.");
        tradingOpen = true;
    }

    /**
     * @dev Transfers/Sets lpToken address to a new address (`newLpToken`).
     * Can only be called by the current operator.
     */
    function transferLpToken(address newLpToken) public onlyOperator {
        // Can transfer LP only once!
        require(lpToken == address(0), "UFF: LP Token Transfer can be only be set once");
        lpToken = newLpToken;
    }

    // To receive BNB from SwapRouter when swapping
    receive() external payable {}
}