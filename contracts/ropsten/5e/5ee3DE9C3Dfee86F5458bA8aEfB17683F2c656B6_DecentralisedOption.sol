/**
 *Submitted for verification at Etherscan.io on 2021-12-04
*/

// File: contracts/exchange.sol


pragma solidity 0.8.7;

contract TokenExchange {
    // Hashmap of all tokens to their prices
    mapping(address => uint256) private tokenPrices;

    // Retrieves the current price of the baseToken
    function getBaseTokenPrice(address baseTokenAddress) public view returns (uint256)
    {
        return tokenPrices[baseTokenAddress];
    }
    
    //This is a helper function to help the user see what the cost to exercise an option is currently before they do so
    //Updates lastestCost member of option which is publicly viewable
    function setBaseTokenPrice(address baseTokenAddress, uint256 baseTokenPrice) public {
        tokenPrices[baseTokenAddress] = baseTokenPrice;
    }
}
// File: contracts/ERC20_own.sol


pragma solidity 0.8.7;

contract ERC20 {
    // MAXSUPPLY, supply, fee and minter
    // We use uint256 because it’s most efficient data type in solidity
    // The EVM works with 256bit and if data is smaller
    // further operations are needed to downscale it from 256bit.
    // The variables are private by convention and getters/setters can
    // be used to retrieve or amend them.
    uint256 constant private fee = 0;
    uint256 constant private MAXSUPPLY = 1000000;
    uint256 private supply = 50000;
    address private minter;

    // Event to be emitted on transfer
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    // Event to be emitted on approval
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // Event to be emitted on mintership transfer
    event MintershipTransfer(address indexed previousMinter, address indexed newMinter);

    // Mapping for balances
    mapping (address => uint) public balances;

    // Mapping for allowances
    mapping (address => mapping(address => uint)) public allowances;

    constructor() {
        // Sender's balance gets set to total supply and sender gets assigned as minter
        balances[msg.sender] = supply;
        minter = msg.sender;
    }

    function totalSupply() public view returns (uint256) {
        // Returns total supply
        return supply;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        // Returns the balance of _owner
        return balances[_owner];
    }

    function mint(address receiver, uint256 amount) public returns (bool) {
        // Mint tokens by updating receiver's balance and total supply
        // Total supply must not exceed MAXSUPPLY
        // The sender needs to be the current minter to mint more tokens
        require(msg.sender == minter, "Sender is not the current minter");
        require(totalSupply() + amount <= MAXSUPPLY, "The added supply will exceed the max supply");
        supply += amount;
        balances[receiver] += amount;
        emit Transfer(address(0), receiver, amount);
        return true;
    }

    function burn(uint256 amount) public returns (bool) {
        // Burn tokens by sending tokens to address(0)
        // Must have enough balance to burn
        require(balances[msg.sender] >= amount, "Insufficient balance to burn");
        supply -= amount;
        balances[address(0)] += amount;
        balances[msg.sender] -= amount;
        emit Transfer(msg.sender, address(0), amount);
        return true;
    }

    function transferMintership(address newMinter) public returns (bool) {
        // Transfer mintership to newminter
        // Only incumbent minter can transfer mintership
        // Should emit MintershipTransfer event
        require(msg.sender == minter, "Sender is not the current minter");
        minter = newMinter;
        emit MintershipTransfer(minter, newMinter);
        return true;
    }

    function doTransfer(address _from, address _to, uint256 _value) private returns (bool) {
        // Private method to avoid code duplication between transfer and transferFrom
        // Transfer `_value` tokens from _from to _to
        // _from needs to have enough tokens
        // Transfer value needs to be sufficient to cover fee
        // Emit events for sending to _to and to minter
        require(balances[_from] >= _value, "Insufficient balance");
        require(fee < _value, "Cover fee exceeds the transfer value");
        balances[_from] -= _value;
        balances[_to] += _value - fee;
        balances[minter] += fee;
        emit Transfer(_from, _to, _value - fee);
        emit Transfer(_from, minter, fee);
        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        // Transfer `_value` tokens from sender to `_to`
        return doTransfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        // Transfer `_value` tokens from `_from` to `_to`
        // `_from` needs to have enough tokens and to have allowed sender to spend on his behalf
        require(allowances[_from][msg.sender] >= _value, "Insufficient allowance");
        bool response = doTransfer(_from, _to, _value);
        allowances[_from][msg.sender] -= _value;
        return response;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        // Allow `_spender` to spend `_value` on sender's behalf
        // If an allowance already exists, it should be overwritten
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        // Return how much `_spender` is allowed to spend on behalf of `_owner`
        return allowances[_owner][_spender];
    }
}
// File: contracts/options.sol


pragma solidity 0.8.7;



contract DecentralisedOption {    
    address payable contractAddr;

    address private baseTokenAddress;
    address private tokenExchange;
    address private minter;

    uint private strike;
    uint private premium; 
    
    uint256 constant private MAXSUPPLY = 1000;
    uint256 private supply = 0;

    //Options stored in arrays of structs
    struct optionDynamic {
        uint256 baseTokenPrice;
        uint256 latestCost; //Helper to show last updated cost to exercise
        uint256 expiry;
        bool exercised; //Has option been exercised
        bool canceled; //Has option been canceled
        address payable writer; //Issuer of option
        address payable buyer; //Buyer of option
    }

    optionDynamic[] optionDynamicProps;

    mapping (address => uint) public balances;

    //Kovan feeds: https://docs.chain.link/docs/reference-contracts
    constructor(address _baseTokenAddress, uint _strike, uint _premium, address _tokenExchange) {
        contractAddr = payable(address(this));
        baseTokenAddress = _baseTokenAddress;
        strike = _strike;
        premium = _premium;
        tokenExchange = _tokenExchange;
        minter = msg.sender;
    }

    //Allows user to write a covered call option
    //Takes which token, a strike price(USD per token w/18 decimal places), premium(same unit as token), expiration time(unix) and how many tokens the contract is for
    function writeOption(uint expiry) public {
        // Need to authorize the contract to transfer funds on your behalf
        require(ERC20(baseTokenAddress).transferFrom(msg.sender, contractAddr, 1), "Incorrect amount of TOKEN supplied");
        uint256 baseTokenPrice = TokenExchange(tokenExchange).getBaseTokenPrice(baseTokenAddress);
        uint256 latestCost = baseTokenPrice;
        mint();
        optionDynamicProps.push(optionDynamic(baseTokenPrice, latestCost, expiry, false, false, payable(msg.sender), payable(address(0))));
    }
    
    //Purchase a call option, needs desired token, ID of option and payment
    function buyOption(uint256 ID) public payable {
        // Transfer premium payment from buyer to writer
        // Need to authorize the contract to transfer funds on your behalf
        require(optionDynamicProps[ID].buyer == address(0), "The option is already bought");
        require(msg.value == premium, "Incorrect amount of ETH sent for premium");
        optionDynamicProps[ID].writer.transfer(premium);
        //require(ERC20(quoteTokenAddress).transferFrom(msg.sender, tokenOpts[ID].writer, tokenOpts[ID].premium), "Incorrect amount of TOKEN sent for premium");
        optionDynamicProps[ID].buyer = payable(msg.sender);

        // send 1 option address to the buyer
        balances[msg.sender] += 1;
    }
    
    // Exercise your call option, needs desired token, ID of option and payment
    function exercise(uint256 ID) public payable {
        // If not expired and not already exercised, allow option owner to exercise
        // To exercise, the strike value*amount equivalent paid to writer (from buyer) and amount of tokens in the contract paid to buyer
        require(optionDynamicProps[ID].buyer == msg.sender, "You do not own this option");
        require(!optionDynamicProps[ID].exercised, "Option has already been exercised");
        require(optionDynamicProps[ID].expiry >= block.timestamp, "Option is expired");
        
        // require that buyer has at least one option address
        require(balances[msg.sender] >= 1);

        uint256 exerciseVal = strike;
        require(msg.value == exerciseVal, "Incorrect ETH amount sent to exercise");
        // Buyer exercises option, exercise cost paid to writer
        optionDynamicProps[ID].writer.transfer(exerciseVal);
        //require(ERC20(tokenOpts[ID].quoteToken).transferFrom(msg.sender, tokenOpts[ID].writer, exerciseVal), "Incorrect TOKEN amount sent to exercise");
        // Pay buyer contract amount of TOKEN
        require(ERC20(baseTokenAddress).transfer(msg.sender, 1), "Error: buyer was not paid");
        optionDynamicProps[ID].exercised = true;

        // get 1 option address from the buyer
        balances[msg.sender] += 1;
        
        // burn it?
    }
            
    //Allows writer to retrieve funds from an expired, non-exercised, non-canceled option
    function retrieveExpiredFunds(uint ID) public {
        require(msg.sender == optionDynamicProps[ID].writer, "You did not write this option");
        require(optionDynamicProps[ID].expiry <= block.timestamp && !optionDynamicProps[ID].exercised && !optionDynamicProps[ID].canceled, "This option is not eligible for withdraw");
        require(ERC20(baseTokenAddress).transfer(optionDynamicProps[ID].writer, 1), "Incorrect amount of TOKEN sent");
        optionDynamicProps[ID].canceled = true;
    }

    //Allows option writer to cancel and get their funds back from an unpurchased option
    function cancelOption(uint ID) public {
        require(msg.sender == optionDynamicProps[ID].writer, "You did not write this option");
        require(!optionDynamicProps[ID].canceled && optionDynamicProps[ID].buyer == address(0), "This option cannot be canceled");
        require(ERC20(baseTokenAddress).transfer(optionDynamicProps[ID].writer, 1), "Incorrect amount of TOKEN sent");
        optionDynamicProps[ID].canceled = true;
    }

    //This is a helper function to help the user see what the cost to exercise an option is currently before they do so
    //Updates lastestCost member of option which is publicly viewable
//    function updateLatestTokenPrice(address baseTokenAddress, uint256 baseTokenPrice) public {
//        tokenOpts[ID].latestCost = tokenExchange.getBaseTokenPrice(baseTokenAddress);
//    }

    function getTokenSupply(address _token) public view returns (uint256) {
        return ERC20(_token).totalSupply();
    }

    function getTokenBalance(address _token, address _owner) public view returns (uint256) {
        return ERC20(_token).balanceOf(_owner);
    }

    function mint() public returns (bool) {
        // Mint tokens by updating receiver's balance and total supply
        // Total supply must not exceed MAXSUPPLY
        // The sender needs to be the current minter to mint more tokens
        require(msg.sender == minter, "Sender is not the current minter");
        require(totalSupply() + 1 <= MAXSUPPLY, "The added supply will exceed the max supply");
        supply += 1;
        balances[msg.sender] += 1;
        return true;
    }

    function burn() public returns (bool) {
        // Burn tokens by sending tokens to address(0)
        // Must have enough balance to burn
        require(balances[msg.sender] >= 1, "Insufficient balance to burn");
        supply -= 1;
        balances[address(0)] += 1;
        balances[msg.sender] -= 1;
        return true;
    }

    function totalSupply() public view returns (uint256) {
        // Returns total supply
        return supply;
    }
}

// why the writer didn't receive the exercised price?
// how to do a put option?

// create the options with constructor specifying premium, price, etc
// so that we can trade them to people and they can see that they own them
// they will be traded like any other erc20 token with fixed premium, etc.
// create a contract to create such options