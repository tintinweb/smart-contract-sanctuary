/**
 *Submitted for verification at Etherscan.io on 2021-10-26
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.22 <=0.8.0;

contract realEstate {
	// Declare state variables in this section
	uint8 private decimals;                             // Decimals of our Shares
	uint8 public tax;                               	// Can Preset Tax rate in constructor. To be changed by government only.
	uint256 constant private MAX_UINT256 = 2**256 - 1;  // Very large number.
	uint256 public totalSupply;                         // Total number of tokens.
    uint256 public tokenPrice;                        // rate charged by mainPropertyOwner for 30 Days of rent.


	string public name;                                 // The name of our house (token). Can be determined in Constructor _propertyID
	string public symbol;                               // The Symbol of our house (token). Can be determined in Constructor _propertySymbol

	address public gov = msg.sender;    	            // Government will deploy contract.
	address public mainPropertyOwner;                   // mainPropertyOwner can change tenant.Can become mainPropertyOwner by claimOwnership if owning > 51% of token.

	address[] public stakeholders;                      // Array of stakeholders. Government can addStakeholder or removeStakeholder. Recipient of token needs to be isStakeholder = true to be able to receive token. mainPropertyOwner & Government are stakeholder by default.

	mapping (address => uint256) public tokens;         // Addresses mapped to token ballances.
	mapping (address => mapping (address => uint256)) private allowed;   // All addresses allow unlimited token withdrawals by the government.
	mapping (address => uint256) public tokensOffered;  //Number of Shares a Stakeholder wants to offer to other stakeholders
    mapping (address => uint256) public tokenSellPrice; // Price per Share a Stakeholder wants to have when offering to other Stakeholders




	// Define events
	event ShareTransfer(address indexed from, address indexed to, uint256 shares);
	event Seizure(address indexed seizedfrom, address indexed to, uint256 shares);
	event ChangedTax(uint256 NewTax);
	event MainPropertyOwner(address NewMainPropertyOwner);
	event NewStakeHolder(address StakeholderAdded);
	event StakeHolderBanned (address banned);
	event Withdrawal (address shareholder, uint256 withdrawn);
	event TokensOffered(address Seller, uint256 AmmountShares, uint256 PricePerShare);
	event TokensSold(address Seller, address Buyer, uint256 TokensSold,uint256 PricePerShare);
    event SetTokenPrice(uint256 WEIs);



	constructor (string memory _propertyID, string memory _propertySymbol, address _mainPropertyOwner, uint256 num_of_tokens, uint8 _tax) {
		tokens[_mainPropertyOwner] = num_of_tokens;                   //one main Shareholder to be declared by government to get all initial shares.
		totalSupply = num_of_tokens;                                  // integer value
		name = _propertyID;
		decimals = 18;
		symbol = _propertySymbol;
		tax = _tax;                                         // set tax for deduction upon rental payment
		mainPropertyOwner = _mainPropertyOwner;
		stakeholders.push(gov);                             //gov & mainPropertyOwner pushed to stakeholdersarray upon construction to allow payout and transfers
		stakeholders.push(mainPropertyOwner);
		allowed[mainPropertyOwner][gov] = MAX_UINT256;      //government can take all token from mainPropertyOwner with seizureFrom
	}

	// Define modifiers in this section
	modifier onlyGov{
	  require(msg.sender == gov);
	  _;
	}

	modifier onlyPropOwner{
	    require(msg.sender == mainPropertyOwner);
	    _;
	}


	// Define functions in this section

	function showTokensOf(address _owner) public view returns (uint256 balance) {       //shows shares for each address.
		return tokens[_owner];
	}

	function isStakeholder(address _address) public view returns(bool, uint256) {      //shows whether someone is a stakeholder.
	    for (uint256 s = 0; s < stakeholders.length; s += 1){
	        if (_address == stakeholders[s]) return (true, s);
	    }
	    return (false, 0);
	}


    //functions of government

    function addStakeholder(address _stakeholder) public onlyGov {      //can add more stakeholders.
		(bool _isStakeholder, ) = isStakeholder(_stakeholder);
		if (!_isStakeholder) stakeholders.push(_stakeholder);
		allowed[_stakeholder][gov] = MAX_UINT256;                       //unlimited allowance to withdraw Shares for Government --> Government can seize shares.
		emit NewStakeHolder (_stakeholder);
    }

	function banStakeholder(address _stakeholder) public onlyGov {          // can remove stakeholder from stakeholders array and...
	    (bool _isStakeholder, uint256 s) = isStakeholder(_stakeholder);
	    if (_isStakeholder){
	        stakeholders[s] = stakeholders[stakeholders.length - 1];
	        stakeholders.pop();
	        seizureFrom (_stakeholder, msg.sender,tokens[_stakeholder]);    //...seizes shares
	        emit StakeHolderBanned(_stakeholder);
	    }
	}

	function setTax (uint8 _x) public onlyGov {                             //set new tax rate (for incoming rent being taxed with %)
	   require( _x <= 100, "Valid tax rate  (0% - 100%) required" );
	   tax = _x;
	   emit ChangedTax (tax);
	}


    // Hybrid Governmental

	function seizureFrom(address _from, address _to, uint256 _value) public returns (bool success) {           //government has unlimited allowance, therefore  can seize all assets from every stakeholder. Function also used to buyShares from Stakeholder.
		uint256 allowance = allowed[_from][msg.sender];
		require(tokens[_from] >= _value && allowance >= _value);
		tokens[_to] += _value;
		tokens[_from] -= _value;
		if (allowance < MAX_UINT256) {
			allowed[_from][msg.sender] -= _value;
		}
		emit Seizure(_from, _to, _value);
		return true;
	}

    //mainPropertyOwner functions
    
    function setTokenPrice(uint256 _token_price) public onlyPropOwner{               //mainPropertyOwner can set rentPer30Day in WEI
	    tokenPrice = _token_price;
	    emit SetTokenPrice(tokenPrice);
    }

    //Stakeholder functions

    function offerShares(uint256 _tokensOffered, uint256 _tokenSellPrice) public{       //Stakeholder can offer # of Shares for  Price per Share
        (bool _isStakeholder, ) = isStakeholder(msg.sender);
        require(_isStakeholder);
        require(_tokensOffered <= tokens[msg.sender]);  
        tokensOffered[msg.sender] = _tokensOffered;
        tokenSellPrice[msg.sender] = _tokenSellPrice;
        emit TokensOffered(msg.sender, _tokensOffered, _tokenSellPrice);
    }

    function buyShares (uint256 _tokensToBuy, address payable _from) public payable{    //Stakeholder can buy shares from seller for sellers price * ammount of shares
        (bool _isStakeholder, ) = isStakeholder(msg.sender);
        require(_isStakeholder);
        require(msg.value == _tokensToBuy * tokenSellPrice[_from] && _tokensToBuy <= tokensOffered[_from] && _tokensToBuy <= tokens[_from] &&_from != msg.sender); //
        allowed[_from][msg.sender] = _tokensToBuy;
        seizureFrom(_from, msg.sender, _tokensToBuy);
        tokensOffered[_from] -= _tokensToBuy;
        _from.transfer(msg.value);
        emit TokensSold(_from, msg.sender, _tokensToBuy, tokenSellPrice[_from]);    
    }

	function transfer(address _recipient, uint256 _amount) public returns (bool) {      //transfer of Token, requires isStakeholder
        (bool isStakeholderX, ) = isStakeholder(_recipient);
	    require(isStakeholderX);
	    require(tokens[msg.sender] >= _amount);
	    tokens[msg.sender] -= _amount;
	    tokens[_recipient] += _amount;
	    emit ShareTransfer(msg.sender, _recipient, _amount);
	    return true;
	 }

	function claimOwnership () public {             //claim main property ownership
		require(tokens[msg.sender] > (totalSupply /2) && msg.sender != mainPropertyOwner,"Error. You do not own more than 50% of the property tokens or you are the main owner allready");
		mainPropertyOwner = msg.sender;
		emit MainPropertyOwner(mainPropertyOwner);
	}

    //falback
    receive () external payable {                   //fallback function returns ether back to origin
        payable(msg.sender).transfer(msg.value);
    }
}