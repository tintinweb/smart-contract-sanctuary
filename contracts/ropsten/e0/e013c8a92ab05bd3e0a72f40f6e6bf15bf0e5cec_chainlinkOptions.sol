/**
 *Submitted for verification at Etherscan.io on 2021-12-07
*/

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

// File: contracts/optionTrading.sol


pragma solidity 0.8.7;


contract chainlinkOptions {    
    address payable contractAddr;
    
    //Options stored in arrays of structs
    struct option {
        address baseToken;    
        uint256 baseTokenPrice;
        uint256 strike; //Price in wei option allows buyer to purchase tokens at
        uint256 premium; //Fee in contract token that option writer charges
        uint256 expiry; //Unix timestamp of expiration time
        uint256 amount; //Amount of tokens the option contract is for
        bool exercised; //Has option been exercised
        bool canceled; //Has option been canceled
        address payable writer; //Issuer of option
        address payable buyer; //Buyer of option
    }

    option[] public tokenOpts;

    constructor() {
        contractAddr = payable(address(this));
    }

    //Allows user to write a covered call option
    //Takes which token, a strike price(USD per token w/18 decimal places), premium(same unit as token), expiration time(unix) and how many tokens the contract is for
    function writeOption(address baseTokenAddress, uint256 baseTokenPrice, uint strike, uint premium, uint expiry, uint tknAmt) public {
        // Need to authorize the contract to transfer funds on your behalf
        require(ERC20(baseTokenAddress).transferFrom(msg.sender, contractAddr, tknAmt), "Incorrect amount of TOKEN supplied");
        tokenOpts.push(option(baseTokenAddress, baseTokenPrice, strike, premium, expiry, tknAmt, false, false, payable(msg.sender), payable(address(0))));
    }
    
    //Purchase a call option, needs desired token, ID of option and payment
    function buyOption(uint256 ID) public payable {
        // Transfer premium payment from buyer to writer
        // Need to authorize the contract to transfer funds on your behalf
        require(tokenOpts[ID].buyer == address(0), "The option is already bought");
        require(msg.value == tokenOpts[ID].premium, "Incorrect amount of ETH sent for premium");
        tokenOpts[ID].writer.transfer(tokenOpts[ID].premium);
        tokenOpts[ID].buyer = payable(msg.sender);
    }
    
    //Exercise your call option, needs desired token, ID of option and payment
    function exercise(uint256 ID) public payable {
        //If not expired and not already exercised, allow option owner to exercise
        //To exercise, the strike value*amount equivalent paid to writer (from buyer) and amount of tokens in the contract paid to buyer
        require(tokenOpts[ID].buyer == msg.sender, "You do not own this option");
        require(!tokenOpts[ID].exercised, "Option has already been exercised");
        require(tokenOpts[ID].expiry >= block.timestamp, "Option is expired");
        uint256 exerciseVal = tokenOpts[ID].strike*tokenOpts[ID].amount;
        require(msg.value == exerciseVal, "Incorrect ETH amount sent to exercise");
        //Buyer exercises option, exercise cost paid to writer
        tokenOpts[ID].writer.transfer(exerciseVal);

        //Pay buyer contract amount of TOKEN
        require(ERC20(tokenOpts[ID].baseToken).transfer(msg.sender, tokenOpts[ID].amount), "Error: buyer was not paid");
        tokenOpts[ID].exercised = true;
    }
            
    //Allows writer to retrieve funds from an expired, non-exercised, non-canceled option
    function retrieveExpiredFunds(uint ID) public {
        require(msg.sender == tokenOpts[ID].writer, "You did not write this option");
        require(tokenOpts[ID].expiry <= block.timestamp && !tokenOpts[ID].exercised && !tokenOpts[ID].canceled, "This option is not eligible for withdraw");
        require(ERC20(tokenOpts[ID].baseToken).transfer(tokenOpts[ID].writer, tokenOpts[ID].amount), "Incorrect amount of LINK sent");
        tokenOpts[ID].canceled = true;
    }

    //Allows option writer to cancel and get their funds back from an unpurchased option
    function cancelOption(uint ID) public {
        require(msg.sender == tokenOpts[ID].writer, "You did not write this option");
        require(!tokenOpts[ID].canceled && tokenOpts[ID].buyer == address(0), "This option cannot be canceled");
        require(ERC20(tokenOpts[ID].baseToken).transfer(tokenOpts[ID].writer, tokenOpts[ID].amount), "Incorrect amount of LINK sent");
        tokenOpts[ID].canceled = true;
    }
    
    //This is a helper function to help the user see what the cost to exercise an option is currently before they do so
    //Updates lastestCost member of option which is publicly viewable
    function updateBaseTokenPrice(uint256 ID, uint256 baseTokenPrice) public {
        tokenOpts[ID].baseTokenPrice = baseTokenPrice;
    }

    function getTokenSupply(address _token) public view returns (uint256) {
        return ERC20(_token).totalSupply();
    }

    function getTokenBalance(address _token, address _owner) public view returns (uint256) {
        return ERC20(_token).balanceOf(_owner);
    }
}