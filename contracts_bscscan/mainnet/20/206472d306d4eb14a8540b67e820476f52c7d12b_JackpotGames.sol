/**
 *Submitted for verification at BscScan.com on 2021-10-20
*/

// SPDX-License-Identifier: UNLICENSED

    
    pragma solidity ^0.8.4;
    pragma experimental ABIEncoderV2;
	
	/**
     * @title SafeMath
     * @dev Math operations with safety checks that throw on error
     */
    library SafeMath {    
      function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
      }
    }
	
	library Address {

		function isContract(address account) internal view returns (bool) {

			bytes32 codehash;
			bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
			// solhint-disable-next-line no-inline-assembly
			assembly { codehash := extcodehash(account) }
			return (codehash != 0x0 && codehash != accountHash);
		}

		function toPayable(address account) internal pure returns (address payable) {
			return payable(address(uint160(account)));
		}

		function sendValue(address payable recipient, uint256 amount) internal {
			require(address(this).balance >= amount, "Address: insufficient balance");

			// solhint-disable-next-line avoid-call-value
			// (bool success, ) = recipient.call.value(amount)("");
			(bool success, ) = recipient.call{value:amount}("");
			require(success, 'Address: unable to send value, recipient may have reverted');
		}
	}
		
	
    /**
    * @title BEP20
    */
    abstract contract BEP20 {
        function totalSupply() external view virtual returns (uint256);
        function balanceOf(address account) external view virtual returns (uint256);
        function allowance(address owner, address spender) external view virtual returns (uint256);
        function transfer(address recipient, uint256 amount) external virtual returns (bool);
        function approve(address spender, uint256 amount) external virtual returns (bool);
        function transferFrom(address sender, address recipient, uint256 amount) external virtual returns (bool);

        event Transfer(address indexed from, address indexed to, uint256 value);
        event Approval(address indexed owner, address indexed spender, uint256 value);
    }
    
    contract JackpotGames {
		using SafeMath for uint256;
		using Address for address;
		
        // A Jackpot is defined by the following attributes
        struct Jackpot {
            uint256 id;
            string title;
            string description;
            string category;
            string option0;
            string option1;
            uint256 endDate;
            uint256 decisionDate;
            uint256 JackpotOdds;
            uint256 amount;
            address tokenAddress;
            address creator;
        }
        struct Jackpotter {
            uint256 id;
            uint256 Jackpot_id;
            address payable Jackpotter;
            uint256 amount;
            uint256 option;
        }
    
        Jackpot[] public Jackpots;
		uint[] public posJackpots;
		
        mapping (uint256 => Jackpotter[]) Jackpotters;
    
        mapping (uint256 => uint256) Jackpots_total_option0;
        mapping (uint256 => uint256) Jackpots_total_option1;
		mapping (address => mapping(address => uint256)) public bep20Balances;
        mapping (address => uint256) public bnbBalance;
        mapping (address => uint256) public victories;
        mapping (uint256 => bool) public activeJackpots;
        uint256 public JackpotsCount;
        uint256 public JackpottingsCount;
        mapping(address => uint256) public minJackpotAmount;
		
		address CGC = 0x682BcFf127b8C8e8FceB251831744cFC115e13c6;
		uint256 public CGCMin;
    
        mapping (address => bool) isAdmin;
        address payable public admin;
        mapping (address => bool) public owners;
    
        uint256 public blockTimeStamp;
		
		event CGCSet(uint256 _amount);
		event MinJackpotSet(address _token, uint256 _amount);
		event JackpotCreated(uint256 _id, address _sender);
		event JackpotSent(uint256 _id, address _sender, uint256 _amount, uint256 _option);
		event BEP20Withdrawn(address _sender, uint256 _amount);
		event BNBWithdrawn(address _sender, uint256 _amount);
		event BEP20Deposited(address _sender, address _token, uint256 _amount);
		event JackpotCancelled(uint256 _id);
		event WinnerDeclared(uint256 _id, uint256 _option);
    
        /**
        * @dev Default constructor of the Jackpotting smart contract.
        */
        constructor()  {
            admin = payable(msg.sender);
            blockTimeStamp = block.timestamp;
            isAdmin[msg.sender] = true;
        }
    
    
        modifier onlyAdmin() {
            require(msg.sender == admin);
            _;
        }
    
        modifier onlyAdmins() {
            require(isAdmin[msg.sender]);
            _;
        }
    
        /**
        * @dev Specify min Jackpot for any token
        * @param _token address of the token.
        * @param _amount min amount to create a Jackpot with the _token
        */
        function setMinJackpot(address _token, uint256 _amount) public onlyAdmin {
            require(_amount > 0);
            minJackpotAmount[_token] = _amount;
			emit MinJackpotSet(_token, _amount);
        }
    
        /**
        * @dev Specify minimum CGC balance
        * @param _amount amount
        */
        function setMinCGC(uint256 _amount) public onlyAdmin {
            CGCMin = _amount;
			emit CGCSet(_amount);
        }
    
        /**
        * @dev Create a new Jackpot available starting from now.
        * @param _title Short text title for the Jackpot.
        * @param _description Short textual description of the Jackpot.
        * @param _category Category ID of the Jackpot.
        * @param _option0 Short text for option 0 of the Jackpot.
        * @param _option1 Short text for option 1 of the Jackpot.
        * @param _endDate Jackpot closing date, until when the Jackpots can be placed.
        * @param _decisionDate When will the Jackpot be decided.
        * @param _JackpotOdds 0 For public Jackpots and 1 to 99 for private Jackpots (= odds for option 0 to win).
        * @param _amount Useful for BEP20 currency. For private Jackpots: total Jackpot amount. Never let it empty.
        */
        function createJackpot(
            string memory _title,
            string memory _description,
            string memory _category,
            string memory _option0,
            string memory _option1,
            uint256 _endDate,
            uint256 _decisionDate,
            uint256 _JackpotOdds,
            uint256 _amount,
            address _tokenAddress
        ) public returns(uint256) {
            require(_JackpotOdds >= 0, 'Odds must be at least 0');
            require(_JackpotOdds < 100, 'Odds must be under 100');
            require(_endDate > 600, 'Jackpot duration must be at least 10min');
            require(_endDate < 2592300, 'Jackpot duration cannot be more than 30 days');
            require(_decisionDate > _endDate + block.timestamp, 'Decision date must be after Jackpot closing date');
            require(minJackpotAmount[_tokenAddress] > 0, 'Token not supported!');
            if (_JackpotOdds > 0){
                require(_amount >= (minJackpotAmount[_tokenAddress] * 2), 'Total Jackpot amount has to be higher!');
            }
			
            Jackpots.push(Jackpot({
                id: JackpotsCount,
                title: _title,
                description: _description,
                category: _category,
                option0: _option0,
                option1: _option1,
                endDate: _endDate.add(block.timestamp),
                decisionDate: _decisionDate,
                JackpotOdds: _JackpotOdds,
                amount: _amount,
                tokenAddress: _tokenAddress,
                creator: msg.sender
            }));
			emit JackpotCreated(JackpotsCount, msg.sender);
            
            activeJackpots[JackpotsCount] = true;
    
            JackpotsCount = JackpotsCount.add(1);
            
            return (JackpotsCount);
        }
    
        /**
        * @dev Send a Jackpotting to an existing actif Jackpot
        * @param _JackpotId id of the Jackpot.
        * @param _option 0 or 1, the two available options to Jackpot on.
        * @param _amount always use balance for BEP20. For BNB, use balance if okay, otherwise use msg.value
        */
        function sendJackpot(uint256 _JackpotId, uint256 _option, uint256 _amount) public payable {
			address bnbContract = 0x0000000000000000000000000000000000000000;
            if (Jackpots[_JackpotId].endDate <= block.timestamp){
                activeJackpots[_JackpotId] = false;
            }
            require(_option == 0 || _option == 1, 'Choose a Jackpot option');
            require(_JackpotId < JackpotsCount, 'Jackpot id not found');
            require(Jackpots[_JackpotId].endDate > block.timestamp, 'End date of Jackpot was reached');
            require(activeJackpots[_JackpotId], 'This Jackpot is no longer active');
            require(minJackpotAmount[Jackpots[_JackpotId].tokenAddress] > 0, 'Token not supported!');

            uint256 Jackpot_amount;
            
            if (Jackpots[_JackpotId].tokenAddress == bnbContract){
                Jackpot_amount = msg.value;
            }else{
                require(_amount <= bep20Balances[msg.sender][Jackpots[_JackpotId].tokenAddress], 'Insufficient balance');
                Jackpot_amount = _amount;
            }
            
            // If amount is below minimum Jackpot amount, don't accept
            require(Jackpot_amount >= minJackpotAmount[Jackpots[_JackpotId].tokenAddress], 'Minimum Jackpot amount not reached');
 
            /* private Jackpot, always with fixed odds */
            if (Jackpots[_JackpotId].JackpotOdds > 0) {
                if (_option == 0) {
                    require(Jackpot_amount == (Jackpots[_JackpotId].amount * Jackpots[_JackpotId].JackpotOdds / 100), 'Jackpot amount is invalid');
                }else{
                    require(Jackpot_amount == (Jackpots[_JackpotId].amount * (100 - Jackpots[_JackpotId].JackpotOdds) / 100), 'Jackpot amount is invalid');
                }
            }
			
            // If balance was used, sub from balance
            if (Jackpots[_JackpotId].tokenAddress != bnbContract){
                bep20Balances[msg.sender][Jackpots[_JackpotId].tokenAddress] = (bep20Balances[msg.sender][Jackpots[_JackpotId].tokenAddress]) - Jackpot_amount;
            }
            
            Jackpotters[_JackpotId].push(Jackpotter({
                id: JackpottingsCount,
                Jackpot_id: _JackpotId,
                Jackpotter: payable(msg.sender),
                amount: Jackpot_amount,
                option: _option
            }));
            
            // after the first Jackpot of a public Jackpot, it's added into PosJackpots
			if(Jackpots[_JackpotId].JackpotOdds == 0 && (Jackpots_total_option0[_JackpotId] + Jackpots_total_option0[_JackpotId] <= 0)) {
				posJackpots.push(_JackpotId);
			}
			
			emit JackpotSent(_JackpotId, msg.sender, Jackpot_amount, _option);
			
            if(_option == 0){
                Jackpots_total_option0[_JackpotId] = Jackpots_total_option0[_JackpotId].add(Jackpot_amount);
            }else{
                Jackpots_total_option1[_JackpotId] = Jackpots_total_option1[_JackpotId].add(Jackpot_amount);
            }
            JackpottingsCount = JackpottingsCount.add(1);
            
            // in a private Jackpot, if both Jackpots are made, the Jackpot gets inactive
            if (Jackpots[_JackpotId].JackpotOdds > 0) {
                if(Jackpots_total_option0[_JackpotId] > 0 && Jackpots_total_option1[_JackpotId] > 0)
                activeJackpots[_JackpotId] = false;
            }
        }
    
        /**
        * @dev Get all available Jackpots.
        */
        function getJackpots(uint cursor, uint howMany) public view returns(Jackpot[] memory, uint newCursor) {
            require(howMany > 0, 'More than 1 Jackpots');
			require(cursor >= 0, 'Cursor position wrong');
			
            uint length = howMany;
            if (length > Jackpots.length - cursor) {
                length = Jackpots.length - cursor;
            }
    
            Jackpot[] memory values = new Jackpot[] (length);
            for (uint i = 0; i < length; i++) {
                values[length - i - 1] = Jackpots[cursor + i];
            }
    
            return (values, cursor + length);
        }
    
        /**
        * @dev Get only your own Jackpots or others' Jackpots with at least one Jackpot. Only active Jackpots are gathered.
        */
         function getPositivesJackpots(uint cursor, uint howMany) public view returns(Jackpot[] memory, uint newCursor) {
            require(howMany > 0, 'More than 1 Jackpots');	
			require(cursor >= 0, 'Cursor position wrong');
			
			uint length = howMany;
			
			if (length > posJackpots.length - cursor) {
				length = posJackpots.length - cursor;
			}
			
			Jackpot[] memory values = new Jackpot[] (length);
            
            for (uint i = 0; i < length; i++) {
                if (activeJackpots[posJackpots[i]] && (Jackpots_total_option0[posJackpots[i]] + Jackpots_total_option1[posJackpots[i]] > 0)) {
					// add the positive Jackpot to the list that is returned
                    values[length - i - 1] = Jackpots[cursor + posJackpots[i]];
                } 
            }
			
			return (values, cursor + length);
        }
        
        /**
        * @dev Refresh expired Jackpots
        */
        function updateJackpotsStats(uint cursor, uint howMany) public {
            require(cursor >= 0, 'Cursor position wrong');		
			require(howMany > 1, 'More than 1 Jackpots');	
			
			uint length = howMany;
			if (length > Jackpots.length - cursor) {
				length = Jackpots.length - cursor;
			}

            for (uint256 i = 0; i < length; i++){
                if (Jackpots[i].endDate <= block.timestamp){
                    activeJackpots[length - i - 1] = false;
                }
            }
        }
        
        /**
        * @dev Refresh positive Jackpots list
        */
        function updatePositives(uint cursor, uint howMany) public {
            require(cursor >= 0, 'Cursor position wrong');
			require(howMany > 1, 'More than 1 Jackpots');	
			
			uint length = howMany;
			if (length > posJackpots.length - cursor) {
				length = posJackpots.length - cursor;
			}
			// Remove the entry from posJackpots that are not active anymore
            for (uint256 i = 0; i < length; i++){
                if (!activeJackpots[posJackpots[i]]) {
					posJackpots[i] = posJackpots[posJackpots.length - 1];
					posJackpots.pop();
                }
            }
        }
        
        /**
        * @dev Get number of victories
        * @param _address holder
        */
        function getVictories(address _address) public view returns(uint) {
            return victories[_address];
        }
    
        /**
        * @dev get total number of Jackpots.
        */
        function getJackpotsCount() public view returns(uint256) {
            return JackpotsCount;
        }
		
		/**
        * @dev get number of CGC
		* @param _address holder
        */
        function getCGCBalance(address _address) public view returns(uint) {
			BEP20 _CGC = BEP20(CGC);
			return _CGC.balanceOf(_address);
        }
    
        /**
        * @dev get total amount received for option 0 for a Jackpot.
        * @param _JackpotId.
        */
        function getJackpotTotalOptions0(uint256 _JackpotId) public view returns(uint256) {
            return Jackpots_total_option0[_JackpotId];
        }
    
        /**
        * @dev get total amount received for option 1 for a Jackpot.
        * @param _JackpotId.
        */
        function getJackpotTotalOptions1(uint256 _JackpotId) public view returns(uint256) {
            return Jackpots_total_option1[_JackpotId];
        }
    
        /**
        * @dev get Jackpotters list for a given Jackpot.
        * @param _JackpotId.
        */
        function getJackpotters(uint256 _JackpotId) public view returns (Jackpotter[] memory){
            return Jackpotters[_JackpotId];
        }
    
        /**
        * @dev declare the winning option for a Jackpot or cancel a Jackpot
        * @param _JackpotId.
        * @param _option the winning option for the Jackpot
        */
        function decideJackpot(uint256 _JackpotId, uint256 _option, address[] memory _players, uint[] memory _payouts) public onlyAdmins {
            address bnbContract = 0x0000000000000000000000000000000000000000;
			require(activeJackpots[_JackpotId] == true, 'Jackpot already decided');
			
			// import a multidimensional array .. winners[i][0] = address; winners[i][1] = gains
			// only winners are imported
			
			// BNB
			if (Jackpots[_JackpotId].tokenAddress == bnbContract){
				for(uint256 i = 0; i < _players.length; i++) {
					bnbBalance[_players[i]] = bnbBalance[_players[i]] + _payouts[i];
					if(_option < 999) {
						victories[_players[i]] = victories[_players[i]].add(1);
					}
				}
			} else {
				for(uint256 i = 0; i < _players.length; i++) {
					bep20Balances[_players[i]][Jackpots[_JackpotId].tokenAddress] = (bep20Balances[_players[i]][Jackpots[_JackpotId].tokenAddress]).add(_payouts[i]);
					if(_option < 999) {
						victories[_players[i]] = victories[_players[i]].add(1);
					}
				}
			}
			
			activeJackpots[_JackpotId] = false;
			if(_option < 999) {
				// Jackpot decided, winner declared
				emit WinnerDeclared(_JackpotId, _option);
			} else {
				// Jackpot cancelled
				emit JackpotCancelled(_JackpotId);
			}
        }
    
        /**
        * @dev deposit BEP20 to be used for Jackpotting.
        * @param _amount.
        * @param _token address of the bep20 smart contract
        */
        function depositBEP20(uint256 _amount, address _token) public {
            BEP20 _bep20 = BEP20(_token);
            _bep20.transferFrom(msg.sender, address(this), _amount);
			emit BEP20Deposited(msg.sender, address(this), _amount);
			
            bep20Balances[msg.sender][_token] = (bep20Balances[msg.sender][_token]).add(_amount);
        }
        
        /**
        * @dev withdraw balance.
		* @param _token address
        */
        function withdraw(address _token) public {
            address bnbContract = 0x0000000000000000000000000000000000000000;
			BEP20 _bep20 = BEP20(_token);
			BEP20 _CGC = BEP20(CGC);
			
			require(_CGC.balanceOf(msg.sender) >= CGCMin, 'Not enough CGC');
			
			if(_token == bnbContract) {
				uint256 amount = bnbBalance[msg.sender];
				require(amount > 0, 'Balance must be > 0');
				bnbBalance[msg.sender] = 0;
				payable(msg.sender).transfer(amount);
				emit BNBWithdrawn(msg.sender, amount);
			} else {
				uint256 amount = bep20Balances[msg.sender][_token];
				require(amount > 0, 'Balance must be > 0');
				bep20Balances[msg.sender][_token] = 0;
				_bep20.transfer(msg.sender, amount);
				emit BEP20Withdrawn(msg.sender, amount);
			}
        }
    
        /**
        * @dev Add a new admin with the same previledges except adding a new admin.
        * @param _newAdmin The address of the new admin.
        */
        function addAdmin(address _newAdmin) public onlyAdmin {
            isAdmin[_newAdmin] = true;
        }
    
        /**
        * @dev Check if an address corresponds to an admin.
        * @param _address .
        */
        function checkAdmin(address _address) public view returns(bool) {
            return isAdmin[_address];
        }
    }