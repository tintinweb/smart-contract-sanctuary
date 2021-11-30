/**
 *Submitted for verification at Etherscan.io on 2021-11-30
*/

// File: gist-19152b9f6938c97052bb93361ca26457/ERC20_own.sol


pragma solidity 0.8.7;

contract ERC20 {
    // MAXSUPPLY, supply, fee and minter
    // We use uint256 because it’s most efficient data type in solidity
    // The EVM works with 256bit and if data is smaller
    // further operations are needed to downscale it from 256bit.
    // The variables are private by convention and getters/setters can
    // be used to retrieve or amend them.
    uint256 constant private fee = 1;
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

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// File: @chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol


pragma solidity ^0.8.0;

interface LinkTokenInterface {

  function allowance(
    address owner,
    address spender
  )
    external
    view
    returns (
      uint256 remaining
    );

  function approve(
    address spender,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function balanceOf(
    address owner
  )
    external
    view
    returns (
      uint256 balance
    );

  function decimals()
    external
    view
    returns (
      uint8 decimalPlaces
    );

  function decreaseApproval(
    address spender,
    uint256 addedValue
  )
    external
    returns (
      bool success
    );

  function increaseApproval(
    address spender,
    uint256 subtractedValue
  ) external;

  function name()
    external
    view
    returns (
      string memory tokenName
    );

  function symbol()
    external
    view
    returns (
      string memory tokenSymbol
    );

  function totalSupply()
    external
    view
    returns (
      uint256 totalTokensIssued
    );

  function transfer(
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    returns (
      bool success
    );

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

}

// File: gist-19152b9f6938c97052bb93361ca26457/chainlinkOptions.sol


pragma solidity 0.8.7;




contract chainlinkOptions {
    //Pricefeed interfaces
    AggregatorV3Interface internal priceFeed;
    AggregatorV3Interface internal ethFeed;
    AggregatorV3Interface internal linkFeed;
    //Interface for LINK token functions
    LinkTokenInterface internal LINK;
    
    uint ethPrice;
    uint linkPrice;
    uint tokenPrice;
    //Precomputing hash of strings
    bytes32 ethHash = keccak256(abi.encodePacked("ETH"));
    bytes32 linkHash = keccak256(abi.encodePacked("LINK"));
    address payable contractAddr;
    
    //Options stored in arrays of structs
    struct option {
        uint strike; //Price in USD (18 decimal places) option allows buyer to purchase tokens at
        uint premium; //Fee in contract token that option writer charges
        uint expiry; //Unix timestamp of expiration time
        uint amount; //Amount of tokens the option contract is for
        bool exercised; //Has option been exercised
        uint id; //Unique ID of option, also array index
        uint latestCost; //Helper to show last updated cost to exercise
        address payable writer; //Issuer of option
        address payable buyer; //Buyer of option
    }
    option[] public ethOpts;
    option[] public linkOpts;
    option[] public tokenOpts;

    //Kovan feeds: https://docs.chain.link/docs/reference-contracts
    constructor() {
        priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
        //ETH/USD Kovan feed
        ethFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
        //LINK/USD Kovan feed
        linkFeed = AggregatorV3Interface(0x396c5E36DD0a0F5a5D33dae44368D4193f69a1F0);
        //LINK token address on Kovan
        LINK = LinkTokenInterface(0xa36085F69e2889c224210F603D836748e7dC0088);
        contractAddr = payable(address(this));
    }

    //Returns the latest ETH price
    function getEthPrice() public view returns (uint) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = ethFeed.latestRoundData();
        // If the round is not complete yet, timestamp is 0
        require(timeStamp > 0, "Round not complete");
        //Price should never be negative thus cast int to unit is ok
        //Price is 8 decimal places and will require 1e10 correction later to 18 places
        return uint(price);
    }
    
    //Returns the latest LINK price
    function getLinkPrice() public view returns (uint) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = linkFeed.latestRoundData();
        // If the round is not complete yet, timestamp is 0
        require(timeStamp > 0, "Round not complete");
        //Price should never be negative thus cast int to unit is ok
        //Price is 8 decimal places and will require 1e10 correction later to 18 places
        return uint(price);
    }
    
    //Updates prices to latest
    function updatePrices() internal {
        //ethPrice = 460213959114;
        //linkPrice = 2604556288;
        ethPrice = getEthPrice();
        linkPrice = getLinkPrice();
        tokenPrice = 1;
    }
    
    //Allows user to write a covered call option
    //Takes which token, a strike price(USD per token w/18 decimal places), premium(same unit as token), expiration time(unix) and how many tokens the contract is for
    function writeOption(string memory token, address tokenAddress, uint strike, uint premium, uint expiry, uint tknAmt) public payable {
        bytes32 tokenHash = keccak256(abi.encodePacked(token));
        //require(tokenHash == ethHash || tokenHash == linkHash, "Only ETH and LINK tokens are supported");
        updatePrices();
        if (tokenHash == ethHash) {
            uint256 t = msg.value;
            require(msg.value == tknAmt, "Incorrect amount of ETH supplied"); 
            uint latestCost = (strike*tknAmt)/(ethPrice*10**10); //current cost to exercise in ETH, decimal places corrected
            ethOpts.push(option(strike, premium, expiry, tknAmt, false, ethOpts.length, latestCost, payable(msg.sender), payable(address(0))));
        } else if (tokenHash == linkHash) {
            require(LINK.transferFrom(msg.sender, contractAddr, tknAmt), "Incorrect amount of LINK supplied");
            uint latestCost = (strike*tknAmt)/(linkPrice*10**10);
            linkOpts.push(option(strike, premium, expiry, tknAmt, false, linkOpts.length, latestCost, payable(msg.sender), payable(address(0))));
        } else {
            require(ERC20(tokenAddress).transferFrom(msg.sender, contractAddr, tknAmt), "Incorrect amount of LINK supplied");
            uint latestCost = (strike*tknAmt)/(tokenPrice*10**10);
            tokenOpts.push(option(strike, premium, expiry, tknAmt, false, tokenOpts.length, latestCost, payable(msg.sender), payable(address(0))));
        }
    } 
    
    //Purchase a call option, needs desired token, ID of option and payment
    function buyOption(string memory token, address tokenAddress, uint ID) public payable {
        bytes32 tokenHash = keccak256(abi.encodePacked(token));
        //require(tokenHash == ethHash || tokenHash == linkHash, "Only ETH and LINK tokens are supported");
        updatePrices();
        if (tokenHash == ethHash) {
            //Transfer premium payment from buyer
            require(msg.value == ethOpts[ID].premium, "Incorrect amount of ETH sent for premium");
            //Transfer premium payment to writer
            ethOpts[ID].writer.transfer(ethOpts[ID].premium);
            ethOpts[ID].buyer = payable(msg.sender);
        } else if (tokenHash == linkHash) {
            //Transfer premium payment from buyer to writer
            require(LINK.transferFrom(msg.sender, linkOpts[ID].writer, linkOpts[ID].premium), "Incorrect amount of LINK sent for premium");
            linkOpts[ID].buyer = payable(msg.sender);
        } else {
            require(ERC20(tokenAddress).transferFrom(msg.sender, tokenOpts[ID].writer, tokenOpts[ID].premium), "Incorrect amount of TOKEN sent for premium");
            tokenOpts[ID].buyer = payable(msg.sender);
        }
    }
    
    //Exercise your call option, needs desired token, ID of option and payment
    function exercise(string memory token, address tokenAddress, uint ID) public payable {
        //If not expired and not already exercised, allow option owner to exercise
        //To exercise, the strike value*amount equivalent paid to writer (from buyer) and amount of tokens in the contract paid to buyer
        bytes32 tokenHash = keccak256(abi.encodePacked(token));
        //require(tokenHash == ethHash || tokenHash == linkHash, "Only ETH and LINK tokens are supported");
        if (tokenHash == ethHash) {
            require(ethOpts[ID].buyer == msg.sender, "You do not own this option");
            require(!ethOpts[ID].exercised, "Option has already been exercised");
            require(ethOpts[ID].expiry >= block.timestamp, "Option is expired");
            //Conditions are met, proceed to payouts
            updatePrices();
            //Cost to exercise
            uint exerciseVal = ethOpts[ID].strike*ethOpts[ID].amount;
            //Equivalent ETH value using Chainlink feed
            uint equivEth = exerciseVal/(ethPrice*10**10); //move decimal 10 places right to account for 8 places of pricefeed
            //Buyer exercises option by paying strike*amount equivalent ETH value
            require(msg.value == equivEth, "Incorrect LINK amount sent to exercise");
            //Pay writer the exercise cost
            ethOpts[ID].writer.transfer(equivEth);
            //Pay buyer contract amount of ETH
            payable(msg.sender).transfer(ethOpts[ID].amount);
            ethOpts[ID].exercised = true;
        } else if (tokenHash == linkHash) {
            require(linkOpts[ID].buyer == msg.sender, "You do not own this option");
            require(!linkOpts[ID].exercised, "Option has already been exercised");
            require(linkOpts[ID].expiry >= block.timestamp, "Option is expired");
            updatePrices();
            uint exerciseVal = linkOpts[ID].strike*linkOpts[ID].amount;
            uint equivLink = exerciseVal/(linkPrice*10**10);
            //Buyer exercises option, exercise cost paid to writer
            require(LINK.transferFrom(msg.sender, linkOpts[ID].writer, equivLink), "Incorrect LINK amount sent to exercise");
            //Pay buyer contract amount of LINK
            require(LINK.transfer(msg.sender, linkOpts[ID].amount), "Error: buyer was not paid");
            linkOpts[ID].exercised = true;
        } else {
            require(tokenOpts[ID].buyer == msg.sender, "You do not own this option");
            require(!tokenOpts[ID].exercised, "Option has already been exercised");
            require(tokenOpts[ID].expiry >= block.timestamp, "Option is expired");
            updatePrices();
            uint exerciseVal = tokenOpts[ID].strike*tokenOpts[ID].amount;
            uint equivLink = exerciseVal/(tokenPrice*10**10);
            //Buyer exercises option, exercise cost paid to writer
            require(ERC20(tokenAddress).transferFrom(msg.sender, tokenOpts[ID].writer, equivLink), "Incorrect TOKEN amount sent to exercise");
            //Pay buyer contract amount of TOKEN
            require(ERC20(tokenAddress).transfer(msg.sender, tokenOpts[ID].amount), "Error: buyer was not paid");
            tokenOpts[ID].exercised = true;
        }
    }
    
    //This is a helper function to help the user see what the cost to exercise an option is currently before they do so
    //Updates lastestCost member of option which is publicly viewable
    function updateExerciseCost(string memory token, address tokenAddress, uint ID) public {
        bytes32 tokenHash = keccak256(abi.encodePacked(token));
        require(tokenHash == ethHash || tokenHash == linkHash, "Only ETH and LINK tokens are supported");
        updatePrices();
        if (tokenHash == ethHash) {
            ethOpts[ID].latestCost = ethOpts[ID].strike*ethOpts[ID].amount/(ethPrice*10**10);
        } else if (tokenHash == linkHash) {
            linkOpts[ID].latestCost = linkOpts[ID].strike*linkOpts[ID].amount/(linkPrice*10**10);
        } else {
            tokenOpts[ID].latestCost = tokenOpts[ID].strike*tokenOpts[ID].amount/(tokenPrice*10**10);
        }
    }


    function getDerivedPrice(address _base, address _quote, uint8 _decimals)
        public
        view
        returns (int256)
    {
        require(_decimals > uint8(0) && _decimals <= uint8(18), "Invalid _decimals");
        int256 decimals = int256(10 ** uint256(_decimals));
        ( , int256 basePrice, , , ) = AggregatorV3Interface(_base).latestRoundData();
        uint8 baseDecimals = AggregatorV3Interface(_base).decimals();
        basePrice = scalePrice(basePrice, baseDecimals, _decimals);

        ( , int256 quotePrice, , , ) = AggregatorV3Interface(_quote).latestRoundData();
        uint8 quoteDecimals = AggregatorV3Interface(_quote).decimals();
        quotePrice = scalePrice(quotePrice, quoteDecimals, _decimals);

        return basePrice * decimals / quotePrice;
    }

    function scalePrice(int256 _price, uint8 _priceDecimals, uint8 _decimals)
        internal
        pure
        returns (int256)
    {
        if (_priceDecimals < _decimals) {
            return _price * int256(10 ** uint256(_decimals - _priceDecimals));
        } else if (_priceDecimals > _decimals) {
            return _price / int256(10 ** uint256(_priceDecimals - _decimals));
        }
        return _price;
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice(address _base) public view returns (int) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = AggregatorV3Interface(_base).latestRoundData();
        return price;
    }

    function getTokenSupply(address _token) public view returns (uint256) {
        return ERC20(_token).totalSupply();
    }

    function getTokenBalance(address _token, address _owner) public view returns (uint256) {
        return ERC20(_token).balanceOf(_owner);
    }
}