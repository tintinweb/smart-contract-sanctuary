/**
 *Submitted for verification at BscScan.com on 2021-10-11
*/

// SPDX-License-Identifier: UNLICENSED
    // RPSToken
    // The First Real Time 1v1 Rock Paper Scissors Betting Game on the Blockchain v1.0
    
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
    
    contract RPSTBetting {
		using SafeMath for uint256;
		using Address for address;
		
        // A bet is defined by the following attributes
        struct Bet {
            uint256 id;
            string title;
            string description;
            string category;
            string option0;
            string option1;
            uint256 endDate;
            uint256 decisionDate;
            uint256 betOdds;
            uint256 amount;
            address tokenAddress;
            address creator;
        }
        struct Better {
            uint256 id;
            uint256 bet_id;
            address payable better;
            uint256 amount;
            uint256 option;
        }
    
        Bet[] public bets;
		uint[] public posBets;
		
        mapping (uint256 => Better[]) betters;
    
        mapping (uint256 => uint256) bets_total_option0;
        mapping (uint256 => uint256) bets_total_option1;
		mapping (address => mapping(address => uint256)) public bep20Balances;
        mapping (address => uint256) public bnbBalance;
        mapping (address => uint256) public victories;
        mapping (uint256 => bool) public activeBets;
        uint256 public betsCount;
        uint256 public bettingsCount;
        mapping(address => uint256) public minBetAmount;
		
		address RPST = 0x47a5741FF59ab07D8cE3797DD776f7d0a171aD9b;
		uint256 public RPSTMin;
    
        mapping (address => bool) isAdmin;
        address payable public admin;
        mapping (address => bool) public owners;
    
        uint256 public blockTimeStamp;
		
		event RPSTSet(uint256 _amount);
		event MinBetSet(address _token, uint256 _amount);
		event BetCreated(uint256 _id, address _sender);
		event BetSent(uint256 _id, address _sender, uint256 _amount, uint256 _option);
		event BEP20Withdrawn(address _sender, uint256 _amount);
		event BNBWithdrawn(address _sender, uint256 _amount);
		event BEP20Deposited(address _sender, address _token, uint256 _amount);
		event BetCancelled(uint256 _id);
		event WinnerDeclared(uint256 _id, uint256 _option);
    
        /**
        * @dev Default constructor of the betting smart contract.
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
        * @dev Specify min bet for any token
        * @param _token address of the token.
        * @param _amount min amount to create a bet with the _token
        */
        function setMinBet(address _token, uint256 _amount) public onlyAdmin {
            require(_amount > 0);
            minBetAmount[_token] = _amount;
			emit MinBetSet(_token, _amount);
        }
    
        /**
        * @dev Specify minimum RPST balance
        * @param _amount amount
        */
        function setMinRPST(uint256 _amount) public onlyAdmin {
            RPSTMin = _amount;
			emit RPSTSet(_amount);
        }
    
        /**
        * @dev Create a new bet available starting from now.
        * @param _title Short text title for the bet.
        * @param _description Short textual description of the bet.
        * @param _category Category ID of the bet.
        * @param _option0 Short text for option 0 of the bet.
        * @param _option1 Short text for option 1 of the bet.
        * @param _endDate Bet closing date, until when the bets can be placed.
        * @param _decisionDate When will the bet be decided.
        * @param _betOdds 0 For public bets and 1 to 99 for private bets (= odds for option 0 to win).
        * @param _amount Useful for BEP20 currency. For private bets: total bet amount. Never let it empty.
        */
        function createBet(
            string memory _title,
            string memory _description,
            string memory _category,
            string memory _option0,
            string memory _option1,
            uint256 _endDate,
            uint256 _decisionDate,
            uint256 _betOdds,
            uint256 _amount,
            address _tokenAddress
        ) public returns(uint256) {
            require(_betOdds >= 0, 'Odds must be at least 0');
            require(_betOdds < 100, 'Odds must be under 100');
            require(_endDate > 600, 'Bet duration must be at least 10min');
            require(_endDate < 2592300, 'Bet duration cannot be more than 30 days');
            require(_decisionDate > _endDate + block.timestamp, 'Decision date must be after bet closing date');
            require(minBetAmount[_tokenAddress] > 0, 'Token not supported!');
            if (_betOdds > 0){
                require(_amount >= (minBetAmount[_tokenAddress] * 2), 'Total bet amount has to be higher!');
            }
			
            bets.push(Bet({
                id: betsCount,
                title: _title,
                description: _description,
                category: _category,
                option0: _option0,
                option1: _option1,
                endDate: _endDate.add(block.timestamp),
                decisionDate: _decisionDate,
                betOdds: _betOdds,
                amount: _amount,
                tokenAddress: _tokenAddress,
                creator: msg.sender
            }));
			emit BetCreated(betsCount, msg.sender);
            
            activeBets[betsCount] = true;
    
            betsCount = betsCount.add(1);
            
            return (betsCount);
        }
    
        /**
        * @dev Send a betting to an existing actif bet
        * @param _betId id of the bet.
        * @param _option 0 or 1, the two available options to bet on.
        * @param _amount always use balance for BEP20. For BNB, use balance if okay, otherwise use msg.value
        */
        function sendBet(uint256 _betId, uint256 _option, uint256 _amount) public payable {
			address bnbContract = 0x0000000000000000000000000000000000000000;
            if (bets[_betId].endDate <= block.timestamp){
                activeBets[_betId] = false;
            }
            require(_option == 0 || _option == 1, 'Choose a bet option');
            require(_betId < betsCount, 'Bet id not found');
            require(bets[_betId].endDate > block.timestamp, 'End date of bet was reached');
            require(activeBets[_betId], 'This bet is no longer active');
            require(minBetAmount[bets[_betId].tokenAddress] > 0, 'Token not supported!');

            uint256 bet_amount;
            
            if (bets[_betId].tokenAddress == bnbContract){
                bet_amount = msg.value;
            }else{
                require(_amount <= bep20Balances[msg.sender][bets[_betId].tokenAddress], 'Insufficient balance');
                bet_amount = _amount;
            }
            
            // If amount is below minimum bet amount, don't accept
            require(bet_amount >= minBetAmount[bets[_betId].tokenAddress], 'Minimum bet amount not reached');
 
            /* private bet, always with fixed odds */
            if (bets[_betId].betOdds > 0) {
                if (_option == 0) {
                    require(bet_amount == (bets[_betId].amount * bets[_betId].betOdds / 100), 'Bet amount is invalid');
                }else{
                    require(bet_amount == (bets[_betId].amount * (100 - bets[_betId].betOdds) / 100), 'Bet amount is invalid');
                }
            }
			
            // If balance was used, sub from balance
            if (bets[_betId].tokenAddress != bnbContract){
                bep20Balances[msg.sender][bets[_betId].tokenAddress] = (bep20Balances[msg.sender][bets[_betId].tokenAddress]) - bet_amount;
            }
            
            betters[_betId].push(Better({
                id: bettingsCount,
                bet_id: _betId,
                better: payable(msg.sender),
                amount: bet_amount,
                option: _option
            }));
            
            // after the first bet of a public bet, it's added into Posbets
			if(bets[_betId].betOdds == 0 && (bets_total_option0[_betId] + bets_total_option0[_betId] <= 0)) {
				posBets.push(_betId);
			}
			
			emit BetSent(_betId, msg.sender, bet_amount, _option);
			
            if(_option == 0){
                bets_total_option0[_betId] = bets_total_option0[_betId].add(bet_amount);
            }else{
                bets_total_option1[_betId] = bets_total_option1[_betId].add(bet_amount);
            }
            bettingsCount = bettingsCount.add(1);
            
            // in a private bet, if both bets are made, the bet gets inactive
            if (bets[_betId].betOdds > 0) {
                if(bets_total_option0[_betId] > 0 && bets_total_option1[_betId] > 0)
                activeBets[_betId] = false;
            }
        }
    
        /**
        * @dev Get all available bets.
        */
        function getBets(uint cursor, uint howMany) public view returns(Bet[] memory, uint newCursor) {
            require(howMany > 0, 'More than 1 bets');
			require(cursor >= 0, 'Cursor position wrong');
			
            uint length = howMany;
            if (length > bets.length - cursor) {
                length = bets.length - cursor;
            }
    
            Bet[] memory values = new Bet[] (length);
            for (uint i = 0; i < length; i++) {
                values[length - i - 1] = bets[cursor + i];
            }
    
            return (values, cursor + length);
        }
    
        /**
        * @dev Get only your own bets or others' bets with at least one bet. Only active bets are gathered.
        */
         function getPositivesBets(uint cursor, uint howMany) public view returns(Bet[] memory, uint newCursor) {
            require(howMany > 0, 'More than 1 bets');	
			require(cursor >= 0, 'Cursor position wrong');
			
			uint length = howMany;
			
			if (length > posBets.length - cursor) {
				length = posBets.length - cursor;
			}
			
			Bet[] memory values = new Bet[] (length);
            
            for (uint i = 0; i < length; i++) {
                if (activeBets[posBets[i]] && (bets_total_option0[posBets[i]] + bets_total_option1[posBets[i]] > 0)) {
					// add the positive Bet to the list that is returned
                    values[length - i - 1] = bets[cursor + posBets[i]];
                } 
            }
			
			return (values, cursor + length);
        }
        
        /**
        * @dev Refresh expired bets
        */
        function updateBetsStats(uint cursor, uint howMany) public {
            require(cursor >= 0, 'Cursor position wrong');		
			require(howMany > 1, 'More than 1 bets');	
			
			uint length = howMany;
			if (length > bets.length - cursor) {
				length = bets.length - cursor;
			}

            for (uint256 i = 0; i < length; i++){
                if (bets[i].endDate <= block.timestamp){
                    activeBets[length - i - 1] = false;
                }
            }
        }
        
        /**
        * @dev Refresh positive Bets list
        */
        function updatePositives(uint cursor, uint howMany) public {
            require(cursor >= 0, 'Cursor position wrong');
			require(howMany > 1, 'More than 1 bets');	
			
			uint length = howMany;
			if (length > posBets.length - cursor) {
				length = posBets.length - cursor;
			}
			// Remove the entry from posBets that are not active anymore
            for (uint256 i = 0; i < length; i++){
                if (!activeBets[posBets[i]]) {
					posBets[i] = posBets[posBets.length - 1];
					posBets.pop();
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
        * @dev get total number of bets.
        */
        function getBetsCount() public view returns(uint256) {
            return betsCount;
        }
		
		/**
        * @dev get number of RPST
		* @param _address holder
        */
        function getRPSTBalance(address _address) public view returns(uint) {
			BEP20 _RPST = BEP20(RPST);
			return _RPST.balanceOf(_address);
        }
    
        /**
        * @dev get total amount received for option 0 for a bet.
        * @param _betId.
        */
        function getBetTotalOptions0(uint256 _betId) public view returns(uint256) {
            return bets_total_option0[_betId];
        }
    
        /**
        * @dev get total amount received for option 1 for a bet.
        * @param _betId.
        */
        function getBetTotalOptions1(uint256 _betId) public view returns(uint256) {
            return bets_total_option1[_betId];
        }
    
        /**
        * @dev get betters list for a given bet.
        * @param _betId.
        */
        function getBetters(uint256 _betId) public view returns (Better[] memory){
            return betters[_betId];
        }
    
        /**
        * @dev declare the winning option for a bet or cancel a bet
        * @param _betId.
        * @param _option the winning option for the bet
        */
        function decideBet(uint256 _betId, uint256 _option, address[] memory _players, uint[] memory _payouts) public onlyAdmins {
            address bnbContract = 0x0000000000000000000000000000000000000000;
			require(activeBets[_betId] == true, 'Bet already decided');
			
			// import a multidimensional array .. winners[i][0] = address; winners[i][1] = gains
			// only winners are imported
			
			// BNB
			if (bets[_betId].tokenAddress == bnbContract){
				for(uint256 i = 0; i < _players.length; i++) {
					bnbBalance[_players[i]] = bnbBalance[_players[i]] + _payouts[i];
					if(_option < 999) {
						victories[_players[i]] = victories[_players[i]].add(1);
					}
				}
			} else {
				for(uint256 i = 0; i < _players.length; i++) {
					bep20Balances[_players[i]][bets[_betId].tokenAddress] = (bep20Balances[_players[i]][bets[_betId].tokenAddress]).add(_payouts[i]);
					if(_option < 999) {
						victories[_players[i]] = victories[_players[i]].add(1);
					}
				}
			}
			
			activeBets[_betId] = false;
			if(_option < 999) {
				// Bet decided, winner declared
				emit WinnerDeclared(_betId, _option);
			} else {
				// Bet cancelled
				emit BetCancelled(_betId);
			}
        }
    
        /**
        * @dev deposit BEP20 to be used for betting.
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
			BEP20 _RPST = BEP20(RPST);
			
			require(_RPST.balanceOf(msg.sender) >= RPSTMin, 'Not enough RPST');
			
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