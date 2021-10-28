/**
 *Submitted for verification at Etherscan.io on 2021-10-27
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.22 <=0.8.0;

contract RealEstate {
	// Declare state variables in this section

	uint8 public avgBlockTime;                          // Avg block time in seconds.
	uint8 private decimals;                             // Decimals of our Shares. Has to be 0.
	uint8 public tax;                               	// Can Preset Tax rate in constructor. To be changed by government only.
	uint8 public rentalLimitMonths;                     // Months any tenant can pay rent in advance for.
	uint256 public rentalLimitBlocks;                   // ...in Blocks.
	uint256 constant private MAX_UINT256 = 2**256 - 1;  // Very large number.
	uint256 public totalSupply;                         // By default 100 for 100% ownership. Can be changed.
	uint256 public totalSupply2;                        // Only Ether incoming of multiples of this variable will be allowed. This way we can have two itterations of divisions through totalSupply without remainder. There is no Float in ETH, so we need to prevent remainders in division. E.g. 1. iteration (incoming ether value = MultipleOfTokenSupplyPower2) / totalSupply * uint (desired percentage); 2nd iteration ( ether value = MultipleOfTokenSupplyPower) / totalSupply * uint (desired percentage); --> no remainder
	uint256 public rentPer30Day;                        // rate charged by mainPropertyOwner for 30 Days of rent.
	uint256 public accumulated;                         // Globally accumulated funds not distributed to stakeholder yet excluding gov.
	uint256 public blocksPer30Day;                      // Calculated from avgBlockTime. Acts as tiem measurement for rent.
	uint256 public rentalBegin;                         // begin of rental(in blocknumber)
	uint256 public occupiedUntill;                      // Blocknumber untill the Property is occupied.
	uint256 private _taxdeduct;                         // ammount of tax to be paid for incoming ether.


	string public name;                                 // The name of our house (token). Can be determined in Constructor _propertyID
	string public symbol;                               // The Symbol of our house (token). Can be determined in Constructor _propertySymbol

	address public gov = msg.sender;    	            // Government will deploy contract.
	address public mainPropertyOwner;                   // mainPropertyOwner can change tenant.Can become mainPropertyOwner by claimOwnership if owning > 51% of token.
	address public tenant;                              // only tenant can pay the Smart Contract.

	uint256 public sharePrice;

	address[] public stakeholders;                      // Array of stakeholders. Government can addStakeholder or removeStakeholder. Recipient of token needs to be isStakeholder = true to be able to receive token. mainPropertyOwner & Government are stakeholder by default.

	mapping (address => uint256) public revenues;       // Distributed revenue account ballance for each stakeholder including gov.
	mapping (address => uint256) public shares;         // Addresses mapped to token ballances.
	mapping (address => mapping (address => uint256)) private allowed;   // All addresses allow unlimited token withdrawals by the government.
	mapping (address => uint256) public rentpaidUntill; //Blocknumber untill the rent is paid.
	mapping (address => uint256) public sharesOffered;  //Number of Shares a Stakeholder wants to offer to other stakeholders
    mapping (address => uint256) public shareSellPrice; // Price per Share a Stakeholder wants to have when offering to other Stakeholders




	// Define events


	event ShareTransfer(address indexed from, address indexed to, uint256 shares);
	event Seizure(address indexed seizedfrom, address indexed to, uint256 shares);
	event ChangedTax(uint256 NewTax);
	event ChangedSharePrice(uint256 share_price);
	event MainPropertyOwner(address NewMainPropertyOwner);
	event NewStakeHolder(address StakeholderAdded);
	event CurrentlyEligibletoPayRent(address Tenant);
	event PrePayRentLimit (uint8 Months);
	event AvgBlockTimeChangedTo(uint8 s);
	event RentPer30DaySetTo (uint256 WEIs);
	event StakeHolderBanned (address banned);
	event RevenuesDistributed (address shareholder, uint256 gained, uint256 total);
	event Withdrawal (address shareholder, uint256 withdrawn);
	event Rental (uint256 date, address renter, uint256 rentPaid, uint256 tax, uint256 distributableRevenue, uint256 rentedFrom, uint256 rentedUntill);
	event SharesOffered(address Seller, uint256 AmmountShares, uint256 PricePerShare);
	event SharesSold(address Seller, address Buyer, uint256 SharesSold,uint256 PricePerShare);


	constructor (string memory _propertyID, string memory _propertySymbol, address _mainPropertyOwner, uint256 total_tokens, uint256 _share_price, uint8 _tax, uint8 _avgBlockTime) {
		shares[_mainPropertyOwner] = total_tokens;                   //one main Shareholder to be declared by government to get all initial shares.
		totalSupply = total_tokens;                                  //supply fixed to 100 for now, Can also work with 10, 1000, 10 000...
		totalSupply2 = 10000;                      //above to the power of 2
		name = _propertyID;
		decimals = 0;
		symbol = _propertySymbol;
		tax = _tax;                                         // set tax for deduction upon rental payment
		mainPropertyOwner = _mainPropertyOwner;
		stakeholders.push(gov);                             //gov & mainPropertyOwner pushed to stakeholdersarray upon construction to allow payout and transfers
		stakeholders.push(mainPropertyOwner);
		allowed[mainPropertyOwner][gov] = MAX_UINT256;      //government can take all token from mainPropertyOwner with seizureFrom
		avgBlockTime = _avgBlockTime;                       // 13s recomended. Our representation of Time. Can be changed by gov with function SetAvgBlockTime
	    blocksPer30Day = 60*60*24*30/avgBlockTime;
	    rentalLimitMonths = 12;                                   //rental limit in months can be changed by mainPropertyOwner
	    rentalLimitBlocks = rentalLimitMonths * blocksPer30Day;
		sharePrice = _share_price;
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
	modifier isMultipleOf{
	   require(msg.value % totalSupply2 == 0);              //modulo operation, only allow ether ammounts that are multiles of totalsupply^2. This is because there is no float and we will divide incoming ammounts two times to split it up and we do not want a remainder.
	    _;
	}
	modifier eligibleToPayRent{                             //only one tenant at a time can be allowed to pay rent.
	    require(msg.sender == tenant);
	    _;
	}


	// Define functions in this section

//viewable functions

	function showSharesOf(address _owner) public view returns (uint256 balance) {       //shows shares for each address.
		return shares[_owner];
	}

	function showSharePrice() public view returns (uint256 balance) {       //shows shares for each address.
		return sharePrice;
	}

	 function isStakeholder(address _address) public view returns(bool, uint256) {      //shows whether someone is a stakeholder.
	    for (uint256 s = 0; s < stakeholders.length; s += 1){
	        if (_address == stakeholders[s]) return (true, s);
	    }
	    return (false, 0);
	 }

    function currentTenantCheck (address _tenantcheck) public view returns(bool,uint256){               //only works if from block.number on there is just one tenant, otherwise tells untill when rent is paid.
        require(occupiedUntill == rentpaidUntill[tenant], "The entered address is not the current tenant");
        if (rentpaidUntill[_tenantcheck] > block.number){
        uint256 daysRemaining = (rentpaidUntill[_tenantcheck] - block.number)*avgBlockTime/86400;       //86400 seconds in a day.
        return (true, daysRemaining);                                                                   //gives tenant paid status true or false and days remaining
        }
        else return (false, 0);
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
	        seizureFrom (_stakeholder, msg.sender,shares[_stakeholder]);    //...seizes shares
	        emit StakeHolderBanned(_stakeholder);
	    }
	}

	function setTax (uint8 _x) public onlyGov {                             //set new tax rate (for incoming rent being taxed with %)
	   require( _x <= 100, "Valid tax rate  (0% - 100%) required" );
	   tax = _x;
	   emit ChangedTax (tax);
	}

	function setSharePrice(uint256 _share_price) public onlyGov {                             //set new tax rate (for incoming rent being taxed with %)
	   require( _share_price >= 0);
	   sharePrice = _share_price;
	   emit ChangedSharePrice (_share_price);
	}

	function SetAvgBlockTime (uint8 _sPerBlock) public onlyGov{         //we do not have a forgery proof time measurement in Ethereum. Therefore we count the ammount of blocks. One Block equals to 13s but this can be changed by the government.
	    require(_sPerBlock > 0, "Please enter a Value above 0");
	    avgBlockTime = _sPerBlock;
	    blocksPer30Day = (60*60*24*30) / avgBlockTime;
	    emit AvgBlockTimeChangedTo (avgBlockTime);
	}

   function distribute() public onlyGov {       // accumulated funds are distributed into revenues array for each stakeholder according to how many shares are held by shareholders. Additionally, government gets tax revenues upon each rental payment.
        uint256 _accumulated = accumulated;
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            address stakeholder = stakeholders[s];
            uint256 _shares = showSharesOf(stakeholder);
            uint256 ethertoreceive = (_accumulated/(totalSupply))*_shares;
            accumulated = accumulated - ethertoreceive;
            revenues[stakeholder] = revenues[stakeholder] + ethertoreceive;
            emit RevenuesDistributed(stakeholder,ethertoreceive, revenues[stakeholder]);
        }
   }

//hybrid Governmental

	function seizureFrom(address _from, address _to, uint256 _value) public returns (bool success) {           //government has unlimited allowance, therefore  can seize all assets from every stakeholder. Function also used to buyShares from Stakeholder.
		uint256 allowance = allowed[_from][msg.sender];
		require(shares[_from] >= _value && allowance >= _value);
		shares[_to] += _value;
		shares[_from] -= _value;
		if (allowance < MAX_UINT256) {
			allowed[_from][msg.sender] -= _value;
		}
		emit Seizure(_from, _to, _value);
		return true;
	}

//mainPropertyOwner functions

	function canPayRent(address _tenant) public onlyPropOwner{                  //decide who can pay rent in the future
	     tenant = _tenant;
	     emit CurrentlyEligibletoPayRent (tenant);
	}
	function limitadvancedrent(uint8 _monthstolimit) onlyPropOwner public{      //mainPropertyOwner can decide how many months in advance the property can be rented out max
	    rentalLimitBlocks = _monthstolimit *blocksPer30Day;
	    emit PrePayRentLimit (_monthstolimit);
	}

    function setRentper30Day(uint256 _rent) public onlyPropOwner{               //mainPropertyOwner can set rentPer30Day in WEI
	    rentPer30Day = _rent;
	    emit RentPer30DaySetTo (rentPer30Day);
    }

//Stakeholder functions

    function offerShares(uint256 _sharesOffered, uint256 _shareSellPrice) public{       //Stakeholder can offer # of Shares for  Price per Share
        (bool _isStakeholder, ) = isStakeholder(msg.sender);
        require(_isStakeholder);
        require(_sharesOffered <= shares[msg.sender]);
        sharesOffered[msg.sender] = _sharesOffered;
        shareSellPrice[msg.sender] = _shareSellPrice;
		if (sharePrice > 0 && sharePrice < _shareSellPrice) {
			sharePrice = _shareSellPrice;
		}
	
        emit SharesOffered(msg.sender, _sharesOffered, _shareSellPrice);
    }

    function buyShares (uint256 _sharesToBuy, address payable _from) public payable{    //Stakeholder can buy shares from seller for sellers price * ammount of shares
        (bool _isStakeholder, ) = isStakeholder(msg.sender);
        require(_isStakeholder);
        require(msg.value == _sharesToBuy * shareSellPrice[_from] && _sharesToBuy <= sharesOffered[_from] && _sharesToBuy <= shares[_from] &&_from != msg.sender); //
        allowed[_from][msg.sender] = _sharesToBuy;
        seizureFrom(_from, msg.sender, _sharesToBuy);
        sharesOffered[_from] -= _sharesToBuy;
        _from.transfer(msg.value);
        emit SharesSold(_from, msg.sender, _sharesToBuy,shareSellPrice[_from]);
    }

	function transfer(address _recipient, uint256 _amount) public returns (bool) {      //transfer of Token, requires isStakeholder
        (bool isStakeholderX, ) = isStakeholder(_recipient);
	    require(isStakeholderX);
	    require(shares[msg.sender] >= _amount);
	    shares[msg.sender] -= _amount;
	    shares[_recipient] += _amount;
	    emit ShareTransfer(msg.sender, _recipient, _amount);
	    return true;
	 }



	function claimOwnership () public {             //claim main property ownership
		require(shares[msg.sender] > (totalSupply /2) && msg.sender != mainPropertyOwner,"Error. You do not own more than 50% of the property tokens or you are the main owner allready");
		mainPropertyOwner = msg.sender;
		emit MainPropertyOwner(mainPropertyOwner);
	}



   function withdraw() payable public {          //revenues can be withdrawn from individual shareholders (government can too withdraw its own revenues)
        uint256 revenue = revenues[msg.sender];
        revenues[msg.sender] = 0;
        payable(msg.sender).transfer(revenue);
        emit Withdrawal(msg.sender, revenue);
   }

//renter function

    function payRent(uint8 _months) public payable isMultipleOf eligibleToPayRent{          //needs to be eligible to pay rent
        uint256  _rentdue  = _months * rentPer30Day;
        uint256  _additionalBlocks  = _months * blocksPer30Day;
        require (msg.value == _rentdue && block.number + _additionalBlocks < block.number + rentalLimitBlocks);     //sent in Ether has to be _rentdue; additional blocks for rental cannot be higher than limit.
        _taxdeduct = (msg.value/100 * tax);                                 //deduct taxes
        accumulated += (msg.value - _taxdeduct);                                    //accumulate revenues
        revenues[gov] += _taxdeduct;                                                //accumulate taxes
        if (rentpaidUntill[tenant] == 0 && occupiedUntill < block.number) {         //hasn't rented yet & flat is empty
            rentpaidUntill[tenant] = block.number + _additionalBlocks;              //rents from now on
            rentalBegin = block.number;
        }
        else if (rentpaidUntill[tenant] == 0 && occupiedUntill > block.number) {    //hasn't rented yet & flat is occupied
            rentpaidUntill[tenant] = occupiedUntill + _additionalBlocks;            //rents from when it is free
            rentalBegin = occupiedUntill;
        }
        else if ( rentpaidUntill[tenant] > block.number) {                          //is renting, contract is runing
            rentpaidUntill[tenant] += _additionalBlocks;                            //rents from when it is free
            rentalBegin = occupiedUntill;
        }
        else if (rentpaidUntill[tenant] < block.number && occupiedUntill>block.number) {    //has rented before & flat is occupied
            rentpaidUntill[tenant] = occupiedUntill +_additionalBlocks;                     //rents from when it is free
            rentalBegin = occupiedUntill;
        }
        else if (rentpaidUntill[tenant] < block.number && occupiedUntill<block.number) {    //has rented before & flat is empty
            rentpaidUntill[tenant] = block.number + _additionalBlocks;                      //rents from now on
            rentalBegin = block.number;                                                     //has lived before and flat is empgy
        }
        occupiedUntill  = rentpaidUntill[tenant];                                           //set new occupiedUntill
        emit Rental (block.timestamp, msg.sender, msg.value, _taxdeduct, (msg.value - _taxdeduct), rentalBegin, occupiedUntill);
    }


//falback
    receive () external payable {                   //fallback function returns ether back to origin
        payable(msg.sender).transfer(msg.value);
        }
}