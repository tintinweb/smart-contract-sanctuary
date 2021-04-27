/**
 *Submitted for verification at Etherscan.io on 2021-04-27
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

interface IERC20 {
    function transfer(address to_, uint amount_) external returns(bool);
    function balanceOf(address owner_) external returns(uint);
    function isExcluded(address address_) external returns(bool);
}
contract TheTreasureSale {

    // @dev Stores all contributions, one per address.
    // Future contribution will update the user's existing contribution variable.
    struct Contribution {
        address contributor;
        uint spent;
        uint bought;
        uint count;
        bool claimed;
    }
    Contribution[] public contributions;

    // @dev Stores a new entry for each address. Each address is stored only once.
    mapping(address => uint) public contributors;
    mapping(address => bool) public isContributor;

    address public owner;

    IERC20 public token;
    uint constant public FULL_TOKEN = 10**18;

    struct Sale {
        // @dev Timestamp of latest possible contribution.
        uint end;

        // @dev Minimum amount to raise so that the sale is successful.
        // Takes the BNB balane of this contract.
        uint softCap;

        // @dev Maximum amount to raise.
        // Takes the BNB balane of this contract.
        uint hardCap;
        
        // @dev Was the sale started?
        bool started;

        // @dev Is the sale over?
        bool done;

        // @dev Was the sale successful?
        bool successful;

        // @dev The price of a token.
        uint tokensPerBNB;
        
        // @dev The amount of tokens that have not been sold
        // or withdrawn by the owner yet.
        uint unsoldTokens;

        // @dev The amount of tokens that have been sold
        uint soldTokens;

        // @dev The amount of BNB that has been raised.
        uint raised;
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
        require(sale.end > block.timestamp, "Test: Sale is over.");
        _;
    }

    /**
     * @dev Checks if the sale is over.
     * If `success_` is true, code execution only happens when the sale is over and was successful.
     * If `success_` is false, code execution continues when sale is over, no matter if sale was successful or not.
     */
    modifier afterSale(bool success_) {
        if(!success_) {
            require(sale.done, "Test: Sale is not over yet.");
            _;
        }
        else {
            require(sale.done, "Test: Sale is not over yet.");
            require(sale.successful, "Test: Sale was not successful.");
            _;
        }
    }

    constructor(address owner_, address token_) {
        owner = owner_;
        token = IERC20(token_);
    }

    /**
     */
    function getId(address contributor_) public view returns(uint) {
        return contributors[contributor_];
    }
    
    // > Add to contributions[] if not existing and update contributors appropriately
    function buyTokens() external payable whileSale {
        require(msg.value >= 1, "Test: No BNB sent.");
        require(address(this).balance <= sale.hardCap, "Test: Sale hard cap reached.");
        uint tokensToGet_ = msg.value * sale.tokensPerBNB;
        uint refund_;
        uint id_ = getId(msg.sender);

        if(address(this).balance + msg.value >= sale.hardCap) {
            tokensToGet_ = sale.hardCap - address(this).balance;
            refund_ = msg.value - tokensToGet_;
            tokensToGet_ = tokensToGet_ * sale.tokensPerBNB;
            endSale();
        }
        if(!isContributor[msg.sender]) {
            contributions.push(Contribution(msg.sender, 0, 0, 0, false));
            id_ = contributions.length - 1;
            contributors[msg.sender] = id_;
            isContributor[msg.sender] = true;
        }

        contributions[id_].spent += msg.value;
        contributions[id_].bought += tokensToGet_;
        contributions[id_].count++;

        if(refund_ > 0) {
            (bool success_, ) = msg.sender.call{value: refund_}("");
            require(success_, "Test: Refund failed.");
        }
    }

    /**
     * @dev Allows anyone to end the sale under the circumstances that the sale end was reached and the sale isn't done already.
     * This is not possible while or before a sale.
     */
    function endSale() public {
        require(sale.started, "Test: Sale was not started yet.");
        require(!sale.done, "Test: Sale already ended.");
        require(sale.end <= block.timestamp || address(this).balance >= sale.hardCap, "Test: Sale cannot be stopped yet.");
        sale.done = true;

        // Softcap reached, mark sale as successful. Note: `sale.successful` is on standard already false,
        // so there's no need to check if the sale was not successful.
        if(address(this).balance >= sale.softCap) {
            sale.successful = true;
        }
    }

    /**
     * @dev Withdraws purchased tokens after a successful sale.
     */
    function withdrawTokens() external afterSale(true) {
        uint id_ = getId(msg.sender);
        require(isContributor[msg.sender], "Test: Did not contribute to the sale.");
        require(!contributions[id_].claimed, "Test: Tokens already withdrawn.");
        uint tokensToGet_ = contributions[id_].bought;
        contributions[id_].claimed = true;
        token.transfer(msg.sender, tokensToGet_);
    }

    function refund() external afterSale(false) {
        uint id_ = getId(msg.sender);
        require(isContributor[msg.sender], "Test: Did not contribute to the sale.");
        require(!contributions[id_].claimed, "Test: Funds already withdrawn.");
        require(!sale.successful, "Test: Sale was successful.");
        uint refund_ = contributions[id_].spent;
        contributions[id_].claimed = true;
        (bool success_, ) = msg.sender.call{value: refund_}("");
    }

    /**
     * @dev Withdraws unsold tokens and/or, if sale successful, the raised BNB amount.
     * Additonally, for security reasons, the owner can withdraw all tokens before the sale started.
     * This is to allow a migration to a new contract in case of any issues.
     *
     * Requirements:
     * When sale over & successful:
     * - Amount of unsold tokens has to be over 0 
     * OR
     * - BNB balance has to be over 0
     *
     * When sale over & unsuccessful OR not started yet:
     * - Token balance of contract has to be > 0.
     *
     * Note: On an unsuccessful sale it is intended that the owner can withdraw all tokens.
     * Users in such a sale receive their contributed BNB back (on request). 
     */
    function adminWithdraw() external onlyOwner {
        if(sale.started) {
            require(sale.done, "Test: Sale is not over yet.");

            // Withdraws unsold tokens and/or raised BNB
            if(sale.successful) {
                require(sale.unsoldTokens > 0 || address(this).balance > 0, "Test: No tokens or BNB to withdraw");
                if(sale.unsoldTokens > 0) {
                    uint tokenBalance_ = token.balanceOf(address(this));
                    sale.unsoldTokens = 0; 
                    token.transfer(owner, tokenBalance_);
                }
                else {
                    uint balance_ = address(this).balance;
                    (bool success_, ) = owner.call{value: balance_}("");
                    require(success_, "Test: Transfer failed.");
                }
            }

            // Withdraws all tokens since sale was not successful
            else {
                uint tokenBalance_ = token.balanceOf(address(this));
                require(tokenBalance_ > 0, "Test: No tokens to withdraw.");
                token.transfer(owner, tokenBalance_);
            }
        }
        else {
            uint tokenBalance_ = token.balanceOf(address(this));
            require(tokenBalance_ > 0, "Test: No tokens to withdraw.");
            token.transfer(owner, tokenBalance_);
        }
    }

    // > Starts the token sale with the amount of tokens this contract owns.
    function startSale(uint end_, uint softCap_, uint hardCap_, uint tokensPerBNB_) external onlyOwner {
        require(token.isExcluded(address(this)), "Test: Sale contract is not excluded.");
        require(token.balanceOf(address(this)) / sale.tokensPerBNB >= sale.hardCap, "Test: Not enough tokens to cover hard cap raise. Send more tokens.");
        require(!sale.started && !sale.done, "Test: Sale is either already started or already done.");
        sale.end = end_;
        sale.softCap = softCap_;
        sale.hardCap = hardCap_;
        sale.started = true;
        sale.tokensPerBNB = tokensPerBNB_;
    }

    // @dev ONLY WHILE TESTING - REMOVE LATER
    function reset(uint end_, uint softCap_, uint hardCap_, address token_, uint tokensPerBNB_) external onlyOwner {
        sale.end = end_;
        sale.softCap = softCap_;
        sale.hardCap = hardCap_;
        sale.started = false;
        sale.done = false;
        sale.successful = false;
        sale.tokensPerBNB = tokensPerBNB_;
        sale.unsoldTokens = 0;
        sale.soldTokens = 0;
        sale.raised = 0;
        token = IERC20(token_);
        uint tokenBalance_ = token.balanceOf(address(this));
        if(tokenBalance_ > 0) {
            token.transfer(owner, tokenBalance_);
        }
        uint balance_ = address(this).balance;
        if(balance_ > 0) {
            (bool success_, ) = msg.sender.call{value: balance_}("");
            require(success_, "Test: Transfer failed.");
        }
    }

}