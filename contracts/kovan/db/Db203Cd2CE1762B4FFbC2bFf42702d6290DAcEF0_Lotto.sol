// SPDX-License-Identifier: GPL-3.0



pragma solidity ^0.6.8;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Dingo is ERC20, Ownable {
    constructor() ERC20("Dingo", "Dingo") public {
      
    }

    function mint(address to, uint256 amount) public onlyOwner  {
        _mint(to, amount);
    }

    function burn(uint256 _value) public {
        _burn(msg.sender, _value);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma experimental ABIEncoderV2;

pragma solidity ^0.6.8;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Dingo_Token.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract Lotto is VRFConsumerBase {
	  //Network: Kovan
	address constant ETHER = address(0); // store Ether in tokens mapping with blank address 
  	address constant VFRC_address = 0xf0d54349aDdcf704F77AE15b96510dEA15cb7952; // VRF Coordinator
  	address constant LINK_address = 0x514910771AF9Ca656af840dff83E8264EcF986CA; // LINK token
	bytes32 constant internal keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
	uint256 public constant feeAmountWei = 50000000000000;
	uint256 public constant ticketAmtWei = 5000000000000000;
	uint256 public constant oneDingo = 1000000000000000000;
	uint256 private constant oneHr = 3600;
	uint256 private constant oneWeek = 604800;
	uint256 public randomResult;
	uint256 private bonus;
	uint256 public bonusTarget;
	uint256 public bonusLaunch;
	uint256 public bonusCount;
	uint256 public drawNumber;
	uint256 public ticketCount;
	uint256 public nextDraw;
	uint256 public drawClose;
	uint256 public initDraw; //holds first ever draw
	uint256 public fee;
	uint256 private devCount;
	uint256 public reserveFunds;
	uint256 public rndFlag;
	uint256[3] public prizePoolBreakDown;

	address public devAddr;
	Dingo public dingoToken;
	bool public dingoOn;
	
	mapping(uint256 => uint256) public prizePool;
 	mapping(address => mapping(address => uint256)) public tokens;
	mapping(uint256 => _Tickets) public Tickets;
	mapping(uint256 => mapping(address => uint256)) public lottoEntries;
	mapping(uint256 => mapping(uint256 => address)) public drawUser;
	mapping(uint256 => uint256 ) public totalUsers;
	mapping(uint256 => bool) public claimedTickets;

	//Track Ticket Possibilities //Store Ticket Combinations (_xxxxxxCombo[draw][ball#][ball#][ball#] = Count)
	mapping(uint => mapping(uint => mapping (uint => mapping(uint => mapping(uint => uint))))) private _fourCombo;
	mapping(uint => mapping(uint => mapping (uint => mapping(uint => mapping(uint => mapping(uint => uint)))))) private _fiveCombo;
	mapping(uint => mapping(uint => mapping (uint => mapping(uint => mapping(uint => mapping(uint => mapping(uint => uint))))))) private _sixCombo;

	mapping(uint256 => _WinningNumbers) public winningNumbers;

	struct _WinningNumbers {
		uint256 draw;
		uint256 drawDate;
		uint256[6] winningNumbers;
		uint256 totalWinnings;
		uint256[3] numWinners;
		uint256[3] winningAmount;
		uint256	timestamp;
	}
	struct _Tickets {
		uint256 id;
		uint256 drawNum;
		address user;
    	uint256[6] lottoNumbers;
    	uint256 timestamp;
    }

	event TicketCreated(
		address indexed owner,
		uint256 indexed ticketNum,
		uint256 indexed drawNum,
		uint256 num_1,
		uint256 num_2,
		uint256 num_3,
		uint256 num_4,
		uint256 num_5,
		uint256 num_6,
		uint256 timestamp
		);
	event Deposit(
			address token,
			address user,
			uint256 amount,
			uint256 balance);

    event Withdraw(
		address token,
		address user,
		uint256 amount,
		uint256 balance
		);
    event Draw(
		uint256 indexed draw,
		uint256 ball_1,
		uint256 ball_2,
		uint256 ball_3,
		uint256 ball_4,
		uint256 ball_5,
		uint256 ball_6
		);

	event ClaimedTicket(
			uint256 indexed draw,
			address indexed owner,
			uint256 indexed ticketnum,
			uint256 amount
			);
	event RandomResult(
			uint256 indexed draw,
			uint256 number,
			string status
			);
	event Received(address indexed sender, uint256 amount);
	//event Bonus()
	
	modifier onlyDev() {
    	require(msg.sender == devAddr, 'only developer can call this function');
    	_;
  	}

	constructor (address _devAddr, uint256 _setDate, Dingo _Dingo_Token, uint256 _bonusTarget)
		VRFConsumerBase(VFRC_address, LINK_address) public {
		devAddr = _devAddr;
		devCount = 0;
		reserveFunds = 0;
		drawNumber = 1;
		bonusLaunch = 5;
		ticketCount = 0;
		dingoToken = _Dingo_Token;
		nextDraw = _setDate;
		initDraw = _setDate;
		drawClose = nextDraw.sub(oneHr);
		bonusTarget = _bonusTarget;
		bonusCount = 0;
		rndFlag = 0;
		prizePoolBreakDown[0] = 50;
		prizePoolBreakDown[1] = 30;
		prizePoolBreakDown[2] = 20;
		dingoOn = false;
		fee = 2 * 10 ** 18; // 0.1 LINK
	} 
	//Public Functions
	
 /* Allows this contract to receive payments */
	receive() external payable {
		emit Received(msg.sender, msg.value);
	}

	function depositEther() public payable {
        tokens[ETHER][msg.sender] = tokens[ETHER][msg.sender].add(msg.value);
        emit Deposit(ETHER, msg.sender, msg.value, tokens[ETHER][msg.sender]);
    }

	function withdrawEther(uint _amount) public {
		require(tokens[ETHER][msg.sender] >= _amount, "No Enough Eth On Account");
		tokens[ETHER][msg.sender] = tokens[ETHER][msg.sender].sub(_amount);
		payable(msg.sender).transfer(_amount);
		emit Withdraw(ETHER, msg.sender, _amount, tokens[ETHER][msg.sender]);
	}

	function depositToken(address _token, uint _amount) public {
		require(_token != ETHER, "Cannot Deposit Eth With Using Deposit Token");
		require(Dingo(_token).transferFrom(msg.sender, address(this), _amount),"Transfer Failed");
		tokens[_token][msg.sender] = tokens[_token][msg.sender].add(_amount);
		emit Deposit(_token, msg.sender, _amount, tokens[_token][msg.sender]);
	}

	function withdrawToken(address _token, uint256 _amount) public {
		require(_token != ETHER, "Cannot Withdraw Eth Using Withdraw Token");
		require(tokens[_token][msg.sender] >= _amount,"Withdraw Amount Greater Than Balance");
		tokens[_token][msg.sender] = tokens[_token][msg.sender].sub(_amount);
		require(Dingo(_token).transfer(msg.sender, _amount), "Transfer failed");
		emit Withdraw(_token, msg.sender, _amount, tokens[_token][msg.sender]);
	}
	//When Dingo Tokens Active Purchase Ticket With Dingo
	function createDingoTicket(uint256[6][] memory _lottoNumbers, uint256  _drawNumber) public {
		//How many tickets were sent over
		uint256 numTickets = _lottoNumbers.length;
		require (dingoOn, "Dingo Token Use Not Active... Yet...");
		require (block.timestamp < drawClose, "Draw Closed");
		require (_drawNumber >= drawNumber, "Ticket Draw Number is Invalid");
		require (Dingo(dingoToken).transferFrom(msg.sender, address(this), numTickets.mul(oneDingo)),"Transfer Failed");
		Dingo(dingoToken).burn(numTickets.mul(oneDingo));
		_storeTickets(_lottoNumbers, _drawNumber);
	}
	//Eth Ticket Purchase
	function createTicket(uint256[6][] memory _lottoNumbers, uint256  _drawNumber) public payable {
		//How many tickets were sent over
		uint256 numTickets = _lottoNumbers.length;
		//Calculate total cost of tickets bought
		uint256 _totalCost = ticketAmtWei.mul(numTickets);

		require (block.timestamp < drawClose, "Draw Closed");
		require (_drawNumber >= drawNumber, "Ticket Draw Number is Invalid");
		require (tokens[ETHER][msg.sender] + msg.value >= _totalCost,"Not enough Eth to buy ticket");

		//Calculate fees
		uint256 _totalFees = feeAmountWei.mul(numTickets);
		
		//Update Total Prize Pool For Draw
		prizePool[_drawNumber] = prizePool[_drawNumber].add(_totalCost).sub(_totalFees);

		//Fee to Dev Account
		tokens[ETHER][devAddr] = tokens[ETHER][devAddr].add(_totalFees);
		//Update sender account
		tokens[ETHER][msg.sender] = tokens[ETHER][msg.sender].add(msg.value).sub(_totalCost);

		bonus = 1;
		if (bonusCount<=bonusTarget) {
			bonus = 2;
		}
		bonusCount = bonusCount.add(numTickets);

		dingoToken.mint(msg.sender, oneDingo.mul(numTickets).mul(bonus).mul(bonusLaunch));
		devCount = devCount.add(numTickets.mul(bonus).mul(bonusLaunch));
		if (devCount>=10){
			uint256 allocation = devCount.div(10);
			dingoToken.mint(devAddr, oneDingo.mul(allocation));
			devCount = devCount.sub(allocation.mul(10));
		}

		_storeTickets(_lottoNumbers, _drawNumber);
	}
	//Get Chank Link Random Number
	function requestRandom() public {
		require(LINK.balanceOf(address(this)) > fee, "Error, not enough LINK - fill contract with faucet");
		require(rndFlag == 0, "Random Number Already Requested");
		require(block.timestamp > nextDraw); //Ensure it's time to draw lottery
		rndFlag = 1;
		dingoToken.mint(msg.sender, oneDingo.mul(100));
		bytes32 requestId = requestRandomness(keyHash, fee);
	}
	//Get Multiple Random Numbers
	function expand(uint256 randomValue, uint256 n) public pure returns (uint256[] memory expandedValues) {
		expandedValues = new uint256[](n);
		for (uint256 i = 0; i < n; i++) {
			expandedValues[i] = uint256(keccak256(abi.encode(randomValue, i)));
		}
		return expandedValues;
	}
	//Calculate Winners
	function drawLottery() public {
			require(rndFlag==2,"Waiting on random request");
			uint256[6] memory _balls;
			uint256[] memory _rndSelection;
			_rndSelection = expand(randomResult, 12);
			uint _rndi = 0;
			bool _unique;
			for (uint i = 0; i < 6; i++){
				do {
					_unique = true;
					_balls[i] = (_rndSelection[_rndi] % 49) + 1;
					if (i > 0){
						for (uint ii = 0; ii < i; ii++){
							if (_balls[i] == _balls[ii]) {
								_unique = false;
								_rndi++;
							}
						}
					}
				} while (!_unique);
				_rndi++;
			}
			//Sort winning numbers into lowest to highest
			_balls = ticketSort(_balls);
			//Generate Combinations for Winning numbers
			checkWinningCombo(_balls, drawNumber);

			for (uint i = 0; i < 3; i++)
			{
				if (winningNumbers[drawNumber].numWinners[i] > 0){
					winningNumbers[drawNumber].totalWinnings += (prizePool[drawNumber] * prizePoolBreakDown[i]) / 100;
					winningNumbers[drawNumber].winningAmount[i] = (prizePool[drawNumber] * prizePoolBreakDown[i]) / winningNumbers[drawNumber].numWinners[i] / 100;
				}
			}
			winningNumbers[drawNumber].drawDate = nextDraw;
			winningNumbers[drawNumber].winningNumbers = _balls;
			winningNumbers[drawNumber].draw = drawNumber;
			winningNumbers[drawNumber].timestamp = block.timestamp;
			
			//Update prizepools and reserve the 'won' funds for claiming
			reserveFunds += winningNumbers[drawNumber].totalWinnings;
			prizePool[drawNumber + 1] += prizePool[drawNumber] - winningNumbers[drawNumber].totalWinnings;
			dingoToken.mint(msg.sender, oneDingo.mul(300));
			bonusCount = 0;
			bonusLaunch = 1;
			emit Draw(
				drawNumber,
				_balls[0],
				_balls[1],
				_balls[2],
				_balls[3],
				_balls[4],
				_balls[5]);
			rndFlag=0;
			drawNumber++;
			nextDraw += oneWeek;
			drawClose = nextDraw - oneHr;
	}

	function claimTickets(uint256[] memory ticketNumbers) public {
		uint tNLength = ticketNumbers.length;
		uint winCount;
		uint256[6] memory numbers;
		uint256[6] memory winning;
		address _owner;
		uint256 _winAmt;
		uint _draw;
		for (uint i = 0; i < tNLength; i++) {
			numbers = Tickets[ticketNumbers[i]].lottoNumbers;
			_draw = Tickets[ticketNumbers[i]].drawNum;
			require(!claimedTickets[i],"Ticket already claimed");
			if (_draw < drawNumber ) {
				_owner = Tickets[ticketNumbers[i]].user;
				winCount = 0;
				winning = winningNumbers[_draw].winningNumbers;
				for (uint wLoop = 0; wLoop < 6; wLoop++) {
					for (uint nLoop = 0; nLoop < 6; nLoop++) {
						if (numbers[nLoop] > winning[wLoop]) {
							nLoop = 6;
						}
						else if (numbers[nLoop] == winning[wLoop]) {
							winCount++;
						}
					}
				}
				_winAmt = 0;
				if (winCount == 4) {
					_winAmt = winningNumbers[_draw].winningAmount[2];
				} else if (winCount == 5) {
					_winAmt = winningNumbers[_draw].winningAmount[1];
				} else if (winCount == 6) {
					_winAmt = winningNumbers[_draw].winningAmount[0];
				}
				reserveFunds = reserveFunds.sub(_winAmt);
				tokens[ETHER][_owner] = tokens[ETHER][_owner].add(_winAmt);
				claimedTickets[ticketNumbers[i]] = true;
				if (winCount > 3) {
					emit ClaimedTicket(
						_draw, 
						_owner, 
						ticketNumbers[i], 
						_winAmt);
				}
			}
		}
	}
	function getDrawData(uint256 _drawNum) public view returns (_WinningNumbers memory) {
		return winningNumbers[_drawNum];
	}
	function balanceOf(address _token, address _user) public view returns (uint256) {
        return tokens[_token][_user];
    }
	function getTicketNumbers(uint256 tickNum) public view returns(uint256, uint256, uint256, uint256, uint256, uint256) {
		return (Tickets[tickNum].lottoNumbers[0],
				Tickets[tickNum].lottoNumbers[1],
				Tickets[tickNum].lottoNumbers[2],
				Tickets[tickNum].lottoNumbers[3],
				Tickets[tickNum].lottoNumbers[4],
				Tickets[tickNum].lottoNumbers[5]);
	}
	function goDingo() public onlyDev {
		//Turn On Ability to purchase with Dingo Tokens
		dingoOn = true;
	}
	function updateFee(uint256 _fee) public onlyDev {
		//Update Link Fee
		fee = _fee;
	}
	function updateDevAddr(address _devAddr) public onlyDev {
		//Update Link Fee
		devAddr = _devAddr;
	}
	function updateBonusTarget(uint _bonusTarget) public onlyDev {
		//Update Link Fee
		bonusTarget = _bonusTarget;
	}
	function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
		randomResult = randomness;
		rndFlag = 2;
		emit RandomResult(
			drawNumber,
			randomResult, 
			"Draw: Received Number"
			);
		//send final random value to the verdict();
		//verdict(randomResult);
	}
	//Private Functions
	function _storeTickets(uint256[6][] memory _lN, uint256  _dN) private {
		uint lNLength = _lN.length;
		for (uint tick = 0; tick < lNLength; tick++) {
			ticketCount++;
			_lN[tick] = ticketSort(_lN[tick]);
			Tickets[ticketCount] = _Tickets(ticketCount, _dN, msg.sender, _lN[tick], block.timestamp);
			_getFourCombo(_lN[tick], _dN);
			_getFiveCombo(_lN[tick], _dN);
			_getSixCombo(_lN[tick], _dN);
			claimedTickets[ticketCount] = false;
			emit TicketCreated(
				msg.sender,
				ticketCount,
				_dN,
				_lN[tick][0],
				_lN[tick][1],
				_lN[tick][2],
				_lN[tick][3],
				_lN[tick][4],
				_lN[tick][5],
				block.timestamp
				);
		}
	}
	function ticketSort(uint256[6] memory _ticketToSort) private pure returns (uint256[6] memory) {
		uint256 _tempBall;
		for (uint i = 0; i < 5; i++)
		{
			for(uint ii = i+1; ii < 6; ii++)
			{
				if(_ticketToSort[i] > _ticketToSort[ii])
				{
					_tempBall = _ticketToSort[i];
					_ticketToSort[i] = _ticketToSort[ii];
					_ticketToSort[ii] = _tempBall;
				}
			}
		}
		return _ticketToSort;
	}
	function _getFourCombo(uint256[6] memory _cT, uint256 _drawNum) private {
		//threeCombo arrary of 6 tickets numbers _cT = check Ticket
		for (uint _chkOne = 0; _chkOne < 3; _chkOne++)
		{
			for (uint _chkTwo = _chkOne + 1; _chkTwo < 4; _chkTwo++)
			{
				for (uint _chkThree = _chkTwo + 1; _chkThree < 5; _chkThree++)
				{
					for (uint _chkFour = _chkThree + 1; _chkFour < 6; _chkFour++)
					{
						// Each iteration of this loop visits a single outcome
						_fourCombo[_drawNum][_cT[_chkOne]][_cT[_chkTwo]][_cT[_chkThree]][_cT[_chkFour]]++;
					}
				}
			}
		}
	}
	function _getFiveCombo(uint256[6] memory _cT, uint256 _drawNum) private {
		//threeCombo arrary of 6 tickets numbers _cT = check Ticket
		for (uint _chkOne = 0; _chkOne < 2; _chkOne++)
		{
			for (uint _chkTwo = _chkOne + 1; _chkTwo < 3; _chkTwo++)
			{
				for (uint _chkThree = _chkTwo + 1; _chkThree < 4; _chkThree++)
				{
					for (uint _chkFour = _chkThree + 1; _chkFour < 5; _chkFour++)
					{
						for (uint _chkFive = _chkFour + 1; _chkFive < 6; _chkFive++)
						{
							// Each iteration of this loop visits a single outcome
							_fiveCombo[_drawNum][_cT[_chkOne]][_cT[_chkTwo]][_cT[_chkThree]][_cT[_chkFour]][_cT[_chkFive]]++;
						}
					}
				}
			}
		}
	}
	function _getSixCombo(uint256[6] memory _cT, uint256 _drawNum) private {
			// Each iteration of this loop visits a single outcome
			if (_sixCombo[_drawNum][_cT[0]][_cT[1]][_cT[2]][_cT[3]][_cT[4]][_cT[5]] == 0){
				_sixCombo[_drawNum][_cT[0]][_cT[1]][_cT[2]][_cT[3]][_cT[4]][_cT[5]] = 1;
			} else {
			_sixCombo[_drawNum][_cT[0]][_cT[1]][_cT[2]][_cT[3]][_cT[4]][_cT[5]]++;}
	}
	function checkWinningCombo(uint256[6] memory _cT, uint256 _drawNum) private {
		uint256 _comboCount;
		winningNumbers[_drawNum].numWinners[0] = _sixCombo[_drawNum][_cT[0]][_cT[1]][_cT[2]][_cT[3]][_cT[4]][_cT[5]];

		_comboCount = 0;
		for (uint _chkOne = 0; _chkOne < 2; _chkOne++)
		{
			for (uint _chkTwo = _chkOne + 1; _chkTwo < 3; _chkTwo++)
			{
				for (uint _chkThree = _chkTwo + 1; _chkThree < 4; _chkThree++)
				{
					for (uint _chkFour = _chkThree + 1; _chkFour < 5; _chkFour++)
					{
						for (uint _chkFive = _chkFour + 1; _chkFive < 6; _chkFive++)
						{
							// Each iteration of this loop visits a single outcome
							_comboCount = _comboCount + _fiveCombo[_drawNum][_cT[_chkOne]][_cT[_chkTwo]][_cT[_chkThree]][_cT[_chkFour]][_cT[_chkFive]];
						}
					}
				}
			}
		}
		winningNumbers[_drawNum].numWinners[1] = _comboCount.sub(winningNumbers[_drawNum].numWinners[0].mul(6));

		_comboCount = 0;
		for (uint _chkOne = 0; _chkOne < 3; _chkOne++)
		{
			for (uint _chkTwo = _chkOne + 1; _chkTwo < 4; _chkTwo++)
			{
				for (uint _chkThree = _chkTwo + 1; _chkThree < 5; _chkThree++)
				{
					for (uint _chkFour = _chkThree + 1; _chkFour < 6; _chkFour++)
					{
						// Each iteration of this loop visits a single outcome
						_comboCount += _fourCombo[_drawNum][_cT[_chkOne]][_cT[_chkTwo]][_cT[_chkThree]][_cT[_chkFour]];
					}
				}
			}
		}
		winningNumbers[_drawNum].numWinners[2] = _comboCount.sub(winningNumbers[_drawNum].numWinners[1].mul(5)).sub(winningNumbers[_drawNum].numWinners[0].mul(15));
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./vendor/SafeMathChainlink.sol";

import "./interfaces/LinkTokenInterface.sol";

import "./VRFRequestIDBase.sol";

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {

  using SafeMathChainlink for uint256;

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(bytes32 requestId, uint256 randomness)
    internal virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 constant private USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(bytes32 _keyHash, uint256 _fee)
    internal returns (bytes32 requestId)
  {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed  = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash].add(1);
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface immutable internal LINK;
  address immutable private vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 /* keyHash */ => uint256 /* nonce */) private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(address _vrfCoordinator, address _link) public {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract VRFRequestIDBase {

  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(bytes32 _keyHash, uint256 _userSeed,
    address _requester, uint256 _nonce)
    internal pure returns (uint256)
  {
    return  uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(
    bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);
  function approve(address spender, uint256 value) external returns (bool success);
  function balanceOf(address owner) external view returns (uint256 balance);
  function decimals() external view returns (uint8 decimalPlaces);
  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);
  function increaseApproval(address spender, uint256 subtractedValue) external;
  function name() external view returns (string memory tokenName);
  function symbol() external view returns (string memory tokenSymbol);
  function totalSupply() external view returns (uint256 totalTokensIssued);
  function transfer(address to, uint256 value) external returns (bool success);
  function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathChainlink {
  /**
    * @dev Returns the addition of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `+` operator.
    *
    * Requirements:
    * - Addition cannot overflow.
    */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  /**
    * @dev Returns the subtraction of two unsigned integers, reverting on
    * overflow (when the result is negative).
    *
    * Counterpart to Solidity's `-` operator.
    *
    * Requirements:
    * - Subtraction cannot overflow.
    */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath: subtraction overflow");
    uint256 c = a - b;

    return c;
  }

  /**
    * @dev Returns the multiplication of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `*` operator.
    *
    * Requirements:
    * - Multiplication cannot overflow.
    */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  /**
    * @dev Returns the integer division of two unsigned integers. Reverts on
    * division by zero. The result is rounded towards zero.
    *
    * Counterpart to Solidity's `/` operator. Note: this function uses a
    * `revert` opcode (which leaves remaining gas untouched) while Solidity
    * uses an invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    * - The divisor cannot be zero.
    */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath: division by zero");
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
    * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
    * Reverts when dividing by zero.
    *
    * Counterpart to Solidity's `%` operator. This function uses a `revert`
    * opcode (which leaves remaining gas untouched) while Solidity uses an
    * invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    * - The divisor cannot be zero.
    */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

