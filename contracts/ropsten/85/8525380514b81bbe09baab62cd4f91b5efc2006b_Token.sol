/**
 *Submitted for verification at Etherscan.io on 2021-07-03
*/

// Watafan-Smart-Contract-Tokens-and-Assets-4.1.sol

/*
Watafan asset Smart Contract v4.1
developed by:
	MarketPay.io , 2017
	https://marketpay.io/
	http://lnked.in/blockchain

	v1.0 https://gist.github.com/computerphysicslab/93405f03880b7eb422013cdbbc3d493f
		+ ERC-20 tokens
		+ Mobile interface
		+ Issuable assets and tradable with tokens

	v2.0 https://gist.github.com/computerphysicslab/f362383f9d3fed26becba48b934bbcfc
		+ onlyOwner modifier
		+ Haltable
		+ safeMath
		+ Added tokenExchangeRate
		+ onlyIssuer modifier
		+ asset state machine

	v3.0 tiny https://gist.github.com/computerphysicslab/7438c8dfdba705faeb7c41af0ae036cc
		+ Removes extra functionalities to make it deployable:
			* Mortal
			* Haltable
			* Mobile interface
			* Asset pointers
			* timestamp
			* onlyOwner, replaced by checking against hardcoded owner address
			* safeMath
			* allocated status for tokens
			* onlyIssuer, replaced by checking against hardcoded issuer addresses

	v4.0 https://gist.github.com/computerphysicslab/ab19e88043a2ab32c8105cac8e82a36e
		+ Rebuilt onlyIssuer modifier, through external contract

	v4.1 https://gist.github.com/computerphysicslab/9159bc65ad6e9beec5f561ed333a07aa
		+ token with 3 decimals
		+ issuer and watafan fees
		+ endpoint for owner to update fees
		+ owner defined at token constructor

*/

pragma solidity ^0.4.13;


/*
 * @title Standard Token Contract
 *
 * ERC20-compliant tokens => https://github.com/ethereum/EIPs/issues/20
 * A token is a fungible virtual good that can be traded.
 * ERC-20 Tokens comply to the standard described in the Ethereum ERC-20 proposal.
 * Basic, standardized Token contract. Defines the functions to check token balances
 * send tokens, send tokens on behalf of a 3rd party and the corresponding approval process.
 *
 */
contract Token {

    // **** BASE FUNCTIONALITY
    // @notice For debugging purposes when using solidity online browser
    function whoAmI() constant returns (address) {
        return msg.sender;
    }

    // SC owners:

    // 0xe5f68950d479fab12797dabbe5a4b0d88ec7a722 => metamask-ropsten
    // address owner = 0x00e5f68950d479fab12797dabbe5a4b0d88ec7a722;

    // 0xa7e3c7c227c72a60e5a2f9912448fb1c21078769 => nodo, juan
    // address owner = 0x00a7e3c7c227c72a60e5a2f9912448fb1c21078769;

    // 0xca35b7d915458ef540ade6068dfe2f44e8fa733c => JS VM solidity-browser
    // address owner = 0x00ca35b7d915458ef540ade6068dfe2f44e8fa733c;

    address owner;

    function isOwner() returns (bool) {
        if (msg.sender == owner) return true;
        return false;
    }

    // **** EVENTS

    // @notice A generic error log
    event Error(string error);


    // **** DATA
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public initialSupply; // Initial and total token supply
    uint256 public totalSupply;
    // bool allocated = false; // True after defining token parameters and initial mint

    // Public variables of the token, all used for display
    // HumanStandardToken is a specialisation of ERC20 defining these parameters
    string public name;
    string public symbol;
    uint8 public decimals;
    string public standard = 'H0.1';

    // **** METHODS

    // Get total amount of tokens, totalSupply is a public var actually
    // function totalSupply() constant returns (uint256 totalSupply) {}

    // Get the account balance of another account with address _owner
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    // Send _amount amount of tokens to address _to
    function transfer(address _to, uint256 _amount) returns (bool success) {
        if (balances[msg.sender] < _amount) {
            Error('transfer: the amount to transfer is higher than your token balance');
            return false;
        }
        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
        Transfer(msg.sender, _to, _amount);

        return true;
    }

    // Send _amount amount of tokens from address _from to address _to
    // The transferFrom method is used for a withdraw workflow, allowing contracts to send
    // tokens on your behalf, for example to "deposit" to a contract address and/or to charge
    // fees in sub-currencies; the command should fail unless the _from account has
    // deliberately authorized the sender of the message via some mechanism
    function transferFrom(address _from, address _to, uint256 _amount) returns (bool success) {
        if (balances[_from] < _amount) {
            Error('transfer: the amount to transfer is higher than the token balance of the source');
            return false;
        }
        if (allowed[_from][msg.sender] < _amount) {
            Error('transfer: the amount to transfer is higher than the maximum token transfer allowed by the source');
            return false;
        }
        balances[_from] -= _amount;
        balances[_to] += _amount;
        allowed[_from][msg.sender] -= _amount;
        Transfer(_from, _to, _amount);

        return true;
    }

    // Allow _spender to withdraw from your account, multiple times, up to the _amount amount.
    // If this function is called again it overwrites the current allowance with _amount.
    function approve(address _spender, uint256 _amount) returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);

        return true;
    }

    // Returns the amount which _spender is still allowed to withdraw from _owner
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    // Constructor: set up token properties and owner token balance
    function Token() {
        // This is the constructor, so owner should be equal to msg.sender, and this method should be called just once
        owner = msg.sender;

        // make sure owner address is configured
        // if(owner == 0x0) throw;

        // owner address can call this function
        // if (msg.sender != owner ) throw;

        // call this function just once
        // if (allocated) throw;

        initialSupply = 100000000 * 1000; // 100M tokens, 3 decimals
        totalSupply = initialSupply;

        name = "Watafan";
        symbol = "FAN";
        decimals = 3;

        balances[owner] = totalSupply;
        Transfer(this, owner, totalSupply);

        // allocated = true;
    }

    // **** EVENTS

    // Triggered when tokens are transferred
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);

    // Triggered whenever approve(address _spender, uint256 _amount) is called
    event Approval(address indexed _owner, address indexed _spender, uint256 _amount);
}


// Interface of issuer contract, just to cast the contract address and make it callable from the asset contract
contract IFIssuers {

    // **** DATA

    // **** FUNCTIONS
    function isIssuer(address _issuer) constant returns (bool);
}


contract Asset is Token {
    // **** DATA

    /** Asset states
    *
    * - Released: Once issued the asset stays as released until sent for free to someone specified by issuer
    * - ForSale: The asset belongs to a user and is open to be sold
    * - Unfungible: The asset cannot be sold, remaining to the user it belongs to.
    */
    enum assetStatus { Released, ForSale, Unfungible }
    // https://ethereum.stackexchange.com/questions/1807/enums-in-solidity

    struct asst {
        uint256 assetId;
        address assetOwner;
        address issuer;
        string content; // a JSON object containing the image data of the asset and its title
        uint256 sellPrice; // in Watafan tokens, how many of them for this asset
        assetStatus status; // behaviour (tradability) of the asset depends upon its status
    }

    mapping (uint256 => asst) assetsById;
    uint256 lastAssetId; // Last assetId
    address public SCIssuers; // Contract that defines who is an issuer and who is not
    uint256 assetFeeIssuer; // Fee percentage for Issuer on every asset sale transaction
    uint256 assetFeeWatafan; // Fee percentage for Watafan on every asset sale transaction


    // **** METHODS

    // Constructor
    function Asset(address _SCIssuers) {
        SCIssuers = _SCIssuers;
    }

    // Queries the asset, knowing the id
    function getAssetById(uint256 assetId) constant returns (uint256 _assetId, address _assetOwner, address _issuer, string _content, uint256 _sellPrice, uint256 _status) {
        return (assetsById[assetId].assetId, assetsById[assetId].assetOwner, assetsById[assetId].issuer, assetsById[assetId].content, assetsById[assetId].sellPrice, uint256(assetsById[assetId].status));
    }

    // Seller sends an owned asset to a buyer, providing its allowance matches token price and transfer the tokens from buyer
    function sendAssetTo(uint256 assetId, address assetBuyer) returns (bool) {
        // assetId must not be zero
        if (assetId == 0) {
            Error('sendAssetTo: assetId must not be zero');
            return false;
        }

        // Check whether the asset belongs to the seller
        if (assetsById[assetId].assetOwner != msg.sender) {
            Error('sendAssetTo: the asset does not belong to you, the seller');
            return false;
        }

        if (assetsById[assetId].sellPrice > 0) { // for non-null token paid transactions
            // Check whether there is balance enough from the buyer to get its tokens
            if (balances[assetBuyer] < assetsById[assetId].sellPrice) {
                Error('sendAssetTo: there is not enough balance from the buyer to get its tokens');
                return false;
            }

            // Check whether there is allowance enough from the buyer to get its tokens
            if (allowance(assetBuyer, msg.sender) < assetsById[assetId].sellPrice) {
                Error('sendAssetTo: there is not enough allowance from the buyer to get its tokens');
                return false;
            }

            // Get the buyer tokens
            if (!transferFrom(assetBuyer, msg.sender, assetsById[assetId].sellPrice)) {
                Error('sendAssetTo: transferFrom failed'); // This shouldn't happen ever, but just in case...
                return false;
            }
        }

        // Set the asset status to Unfungible
        assetsById[assetId].status = assetStatus.Unfungible;

        // Transfer the asset to the buyer
        assetsById[assetId].assetOwner = assetBuyer;

        // Event log
        SendAssetTo(assetId, assetBuyer);

        return true;
    }

    // Buyer gets an asset providing it is in ForSale status, and pays the corresponding tokens to the seller/owner. amount must match assetPrice to have a deal.
    function buyAsset(uint256 assetId, uint256 amount) returns (bool) {
        // assetId must not be zero
        if (assetId == 0) {
            Error('buyAsset: assetId must not be zero');
            return false;
        }

        // Check whether the asset is in ForSale status
        if (assetsById[assetId].status != assetStatus.ForSale) {
            Error('buyAsset: the asset is not for sale');
            return false;
        }

        // Check whether the asset price is the same as amount
        if (assetsById[assetId].sellPrice != amount) {
            Error('buyAsset: the asset price does not match the specified amount');
            return false;
        }

        if (assetsById[assetId].sellPrice > 0) { // for non-null token paid transactions
            // Check whether there is balance enough from the buyer to pay the asset
            if (balances[msg.sender] < assetsById[assetId].sellPrice) {
                Error('buyAsset: there is not enough token balance to buy this asset');
                return false;
            }

            // Calculate the seller income
            uint256 sellerIncome = assetsById[assetId].sellPrice * (1000 - assetFeeIssuer - assetFeeWatafan) / 1000;

            // Send the buyer's tokens to the seller
            if (!transfer(assetsById[assetId].assetOwner, sellerIncome)) {
                Error('buyAsset: seller token transfer failed'); // This shouldn't happen ever, but just in case...
                return false;
            }

            // Send the issuer's fee
            uint256 issuerIncome = assetsById[assetId].sellPrice * assetFeeIssuer / 1000;
            if (!transfer(assetsById[assetId].issuer, issuerIncome)) {
                Error('buyAsset: issuer token transfer failed'); // This shouldn't happen ever, but just in case...
                return false;
            }

            // Send the Watafan's fee
            uint256 watafanIncome = assetsById[assetId].sellPrice * assetFeeWatafan / 1000;
            if (!transfer(owner, watafanIncome)) {
                Error('buyAsset: watafan token transfer failed'); // This shouldn't happen ever, but just in case...
                return false;
            }
        }

        // Set the asset status to Unfungible
        assetsById[assetId].status = assetStatus.Unfungible;

        // Transfer the asset to the buyer
        assetsById[assetId].assetOwner = msg.sender;

        // Event log
        BuyAsset(assetId, amount);

        return true;
    }


    // To limit issue functions just to authorized issuers
    modifier onlyIssuer() {
        if (!IFIssuers(SCIssuers).isIssuer(msg.sender)) {
            Error('onlyIssuer function called by user that is not an authorized issuer');
        } else {
            _;
        }
    }


    // To be called by issueAssetTo() and properly authorized issuers
    function issueAsset(string content, uint256 sellPrice) onlyIssuer internal returns (uint256 nextAssetId) {
        // Find out next asset Id
        nextAssetId = lastAssetId + 1;

        assetsById[nextAssetId].assetId = nextAssetId;
        assetsById[nextAssetId].assetOwner = msg.sender;
        assetsById[nextAssetId].issuer = msg.sender;
        assetsById[nextAssetId].content = content;
        assetsById[nextAssetId].sellPrice = sellPrice;
        assetsById[nextAssetId].status = assetStatus.Released;

        // Update lastAssetId
        lastAssetId++;

        // Event log
        IssueAsset(nextAssetId, msg.sender, sellPrice);

        return nextAssetId;
    }

    // Issuer sends a new free asset to a given user as a gift
    function issueAssetTo(string content, address to) returns (bool) {
        uint256 assetId = issueAsset(content, 0); // 0 tokens, as a gift
        if (assetId == 0) {
            Error('issueAssetTo: asset has not been properly issued');
            return (false);
        }

        // The brand new asset is inmediatly sent to the recipient
        return(sendAssetTo(assetId, to));
    }

    // Seller can block tradability of its assets
    function setAssetUnfungible(uint256 assetId) returns (bool) {
        // assetId must not be zero
        if (assetId == 0) {
            Error('setAssetUnfungible: assetId must not be zero');
            return false;
        }

        // Check whether the asset belongs to the caller
        if (assetsById[assetId].assetOwner != msg.sender) {
            Error('setAssetUnfungible: only owners of the asset are allowed to update its status');
            return false;
        }

        assetsById[assetId].status = assetStatus.Unfungible;

        // Event log
        SetAssetUnfungible(assetId, msg.sender);

        return true;
    }

    // Seller updates the price of its assets and its status to ForSale
    function setAssetPrice(uint256 assetId, uint256 sellPrice) returns (bool) {
        // assetId must not be zero
        if (assetId == 0) {
            Error('setAssetPrice: assetId must not be zero');
            return false;
        }

        // Check whether the asset belongs to the caller
        if (assetsById[assetId].assetOwner != msg.sender) {
            Error('setAssetPrice: only owners of the asset are allowed to set its price and update its status');
            return false;
        }

        assetsById[assetId].sellPrice = sellPrice;
        assetsById[assetId].status = assetStatus.ForSale;

        // Event log
        SetAssetPrice(assetId, msg.sender, sellPrice);

        return true;
    }

    // Owner updates the fees for assets sale transactions
    function setAssetSaleFees(uint256 feeIssuer, uint256 feeWatafan) returns (bool) {
        // Check this is called by owner
        if (!isOwner()) {
            Error('setAssetSaleFees: only Owner is authorized to update asset sale fees.');
            return false;
        }

        // Check new fees are consistent
        if (feeIssuer + feeWatafan > 1000) {
            Error('setAssetSaleFees: added fees exceed 100.0%. Not updated.');
            return false;
        }

        assetFeeIssuer = feeIssuer;
        assetFeeWatafan = feeWatafan;

        // Event log
        SetAssetSaleFees(feeIssuer, feeWatafan);

        return true;
    }



    // **** EVENTS

    // Triggered when a seller sends its asset to a buyer and receives the corresponding tokens
    event SendAssetTo(uint256 assetId, address assetBuyer);

    // Triggered when a buyer sends its tokens to a seller and receives the specified asset
    event BuyAsset(uint256 assetId, uint256 amount);

    // Triggered when the admin issues a new asset
    event IssueAsset(uint256 nextAssetId, address assetOwner, uint256 sellPrice);

    // Triggered when the user updates its asset status to Unfungible
    event SetAssetUnfungible(uint256 assetId, address assetOwner);

    // Triggered when the user updates its asset price and status to ForSale
    event SetAssetPrice(uint256 assetId, address assetOwner, uint256 sellPrice);

    // Triggered when the owner updates the asset sale fees
    event SetAssetSaleFees(uint256 feeIssuer, uint256 feeWatafan);
}