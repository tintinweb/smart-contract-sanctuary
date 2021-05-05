/**
 *Submitted for verification at Etherscan.io on 2021-05-05
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

interface IERC20 {
    function transfer(address to_, uint amount_) external returns(bool);
    function balanceOf(address owner_) external returns(uint);
}
contract TheTreasureSale {

    // @dev Stores a new entry for each address. Each address is stored only once.
    mapping(address => uint) public contributors;
    mapping(address => bool) public isContributor;

    address public owner;

    IERC20 public token;
    uint constant public FULL_TOKEN = 10**18;

    struct Sale {
        // @dev Maximum amount to raise.
        // Takes the BNB balane of this contract.
        uint hardCap;
        
        // @dev Was the sale started?
        bool started;

        // @dev Is the sale over?
        bool done;

        // @dev The price of a token.
        uint tokensPerBNB;

        // @dev The amount of BNB that has been raised.
        uint raised;

        // @dev The amount of tokens that were sold.
        uint sold;

    }
    Sale public sale;

    event Contribute(address indexed address_, uint bnb_);


    /**
     * @dev Only allows the owner to call a specific function.
     */
    modifier onlyOwner {
        require(owner == msg.sender, "Test: owner!");
        _;
    }

    /**
     * @dev Only allows the function to be called while the sale is valid.
     * Note: This also includes the sale being active but the hard cap being reached.
     */
    modifier whileSale {
        require(sale.started, "Test: Sale not started yet.");
        require(!sale.done, "Test: Sale is over.");
        _;
    }

    constructor() {
        owner = 0xaA2fcED70c5B8Ba28fbF8917248ae6b28f01590A;
        token = IERC20(0xC57F9C3399dea394Cb5c014daEa00986575AFD6F);
        sale.tokensPerBNB = 50;
    }
    
    receive() payable external {
        buyTokens();
    }

    // > Add to contributions[] if not existing and update contributors appropriately
    function buyTokens() payable public whileSale {
        require(msg.value >= 1, "Test: No BNB sent.");

        // @dev Checks if user could buy tokens. If hard cap was already reached, then not.
        uint balanceBefore_ = address(this).balance - msg.value;
        require(balanceBefore_ < sale.hardCap, "Test: Sale hard cap reached.");
        
        uint refund_;
        uint contributed_ = msg.value;
        uint tokensToGet_ = contributed_ * sale.tokensPerBNB;

        // @dev If current balance is higher than hard cap, refund too much paid BNB.
        if(address(this).balance > sale.hardCap) {
            // @dev Get remainder/too much paid BNB.
            refund_ = address(this).balance - sale.hardCap;
            contributed_ -= refund_;
            tokensToGet_ = contributed_ * sale.tokensPerBNB;
            endSale();
        }

        sale.sold += tokensToGet_;
        token.transfer(msg.sender, tokensToGet_);

        if(refund_ > 0) {
            (bool success_, ) = msg.sender.call{value: refund_}("");
            require(success_, "Test: Refund failed.");
        }
    }

    /**
     * @dev Allows anyone to end the sale under the circumstances that the hard cap is reached.
     * Allows the owner to stop the sale at any time.
     */
    function endSale() public {
        bool endSuccess_;
        if(address(this).balance >= sale.hardCap) {
            endSuccess_ = true;
        }

        if(msg.sender == owner) {
            endSuccess_ = true;

            uint tokenBalance_ = token.balanceOf(address(this));
            if(tokenBalance_ >= 1) {
                token.transfer(owner, tokenBalance_);
            }

            uint balance_ = address(this).balance;
            if(balance_ >= 1) {
                sale.raised = balance_;
                (bool success_, ) = owner.call{value: balance_}("");
                require(success_, "Test: Transfer failed.");
            }
        }

        sale.done = true;

        require(endSuccess_, "Test: Not possible to end the sale.");
    }

    /**
     * @dev Starts the token sale.
     *
     * Requirements:
     * - Sale has not started yet
     * - Contract has the required tokens
     */
    function startSale() external onlyOwner {
        require(!sale.started, "Test: Token sale already started.");
        sale.started = true;
        sale.hardCap = 140 * 10**18;
    }
}