/**
 *Submitted for verification at Etherscan.io on 2022-01-14
*/

pragma solidity ^0.4.17;

interface IERC20 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address account) public view returns (uint256);
    function allowance(address owner, address spender) public view returns (uint256);

    function transfer(address recipient, uint256 amount) public returns (bool);
    function approve(address spender, uint256 amount) public returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20Basic is IERC20 {
    string public constant name = "Charity Token";
    string public constant symbol = "CTK";
    uint8 public constant decimals = 18;

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;

    uint256 _totalSupply;

    using SafeMath for uint256;


    function ERC20Basic() public {
      // 1 million initial supply to send out to people of interest
      _totalSupply = 1000000*uint256(10)**uint256(decimals);
      balances[msg.sender] = _totalSupply;
    }

    function totalSupply() public view returns (uint256) {
      return _totalSupply;
    }

    function balanceOf(address tokenOwner) public view returns (uint256) {
      return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens) public returns (bool) {
      require(numTokens <= balances[msg.sender]);
      balances[msg.sender] = balances[msg.sender].sub(numTokens);
      balances[receiver] = balances[receiver].add(numTokens);
      Transfer(msg.sender, receiver, numTokens);
      return true;
    }

    function approve(address delegate, uint256 numTokens) public returns (bool) {
      allowed[msg.sender][delegate] = numTokens;
      Approval(msg.sender, delegate, numTokens);
      return true;
    }

    function allowance(address owner, address delegate) public view returns (uint) {
      return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public returns (bool) {
      require(numTokens <= balances[owner]);
      require(numTokens <= allowed[owner][msg.sender]);

      balances[owner] = balances[owner].sub(numTokens);
      allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
      balances[buyer] = balances[buyer].add(numTokens);
      Transfer(owner, buyer, numTokens);
      return true;
    }

    function mint(uint256 numTokens) internal returns (bool) {
      uint256 amt = numTokens*uint256(10)**uint256(decimals);
      balances[msg.sender] = balances[msg.sender].add(amt);
      _totalSupply = _totalSupply.add(amt);
      Transfer(0x0, msg.sender, amt);
      return true;
    }
}

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
}


contract Ownable {
    address public _owner = msg.sender;

    modifier isOwner {
      require(_owner == msg.sender);
      _;
    }

    /// @notice change the owner
    /// @dev This changes the current owner
    /// @param newOwner address of the new owner
    function changeOwner(address newOwner) public isOwner {
      _owner = newOwner;
    }
}

contract Lottery is Ownable, ERC20Basic {
    uint256 public _balance;
    uint256 public _fundBalance;
    uint256 public _charityBalance;

    uint256 public _ticketPrice;
    uint256 public _targetRoundBalance;

    address[] public players;

    // a request object for charity donations
    struct Request {
      string description; // charity description
      uint256 value; // amount to donate
      address recipient;  // recipient address, this can be left empty
      uint256 approvals;  // number of tokens equivalent to number of votes
      bool complete;  // marked if request is completed
    }

    Request[] public requests;

    event WinnerPicked(address winner, uint256 amount);
    event CreateRequest(string description, uint256 value, uint index);
    event FinalizeRequest(uint index);

    modifier whenRoundLimitReached {
      require(_balance >= _targetRoundBalance && players.length > 1);
      _;
    }

    modifier isTokenHolder {
      require(balances[msg.sender] > 0);
      _;
    }

    /// @notice constructor function
    /// @dev This creates a Lottery with the set amounts and defaults if none are selected
    /// @param ticketPrice amount you want to set each ticket price at
    /// @param targetRoundBalance amount you want until claimWinner can be called (a round).
    function Lottery(uint256 ticketPrice, uint256 targetRoundBalance) public {
      if (ticketPrice == 0 && targetRoundBalance == 0) {
        _ticketPrice = 0.01 ether;
        _targetRoundBalance = 0.1 ether;
      } else {
        _ticketPrice = ticketPrice;
        _targetRoundBalance = targetRoundBalance;
      }
    }

    /// @notice Buy ticket(s)
    /// @dev This adds the payer to the array of players, 
    /// higher amounts allows for more tickets to be purchased (up to 20).  
    /// Tokens are minted as part of the process as well
    function buyTicket() public payable {
      require(msg.value >= _ticketPrice);
      if (msg.value > _ticketPrice) {
        uint numTix = msg.value/_ticketPrice;
        mint(numTix);
        if (numTix < 20) {
          for (uint i = 0; i < numTix; i++) {
            players.push(msg.sender);
          }
        } else {
          for (uint j = 0; j < 20; j++) {
            players.push(msg.sender);
          }
        }
      } else {
        players.push(msg.sender);
        mint(1);
      }
      _balance += msg.value;
    }

    /// @notice Claim a winner
    /// @dev This picks a winner and distributes the funds accordingly.  Winner gets half and the other half gets split between the owner and the charity balance.
    function claimWinner() public whenRoundLimitReached {
      bytes32 ticketHash = keccak256(block.difficulty, block.timestamp);
      uint ticketNumber = uint(ticketHash);
      uint index = ticketNumber % players.length;
      uint256 winAmount = _balance/2;
      address winner = players[index];
      uint256 fundBalance = _balance.sub(winAmount);
      _balance = 0;
      _charityBalance = _charityBalance.add(fundBalance/2);
      _fundBalance = _fundBalance.add(fundBalance.sub(fundBalance/2));
      players = new address[](0);
      WinnerPicked(winner, winAmount);
      winner.transfer(winAmount);
    }

    /// @notice get the players
    /// @dev This returns the current set of players
    /// @return array of player addresses
    function getPlayers() public view returns(address[]) {
      return players;
    }

    /// @notice Set the target round balance
    /// @dev Owner can set the new _targetRoundBalance
    /// @param amount amount you want to set as the new _targetRoundBalance
    function setTargetRoundBalance(uint256 amount) public isOwner {
      require(players.length == 0);
      require(amount > _ticketPrice);
      _targetRoundBalance = amount;
    }

    /// @notice Set the ticket price
    /// @dev Owner can set the new _ticketPrice
    /// @param amount amount you want to set as the new _ticketPrice
    function setTicketPrice(uint256 amount) public isOwner {
      require(players.length == 0);
      require(amount < _targetRoundBalance);
      _ticketPrice = amount;
    }

    /// @notice Create a charitable request
    /// @dev Token holders can create a request to spend all or part of the _charityBalance
    /// @param description details about the charity like name and affiliations
    /// @param value amount you want the charity to receive
    /// @param recipient address you want to receive the value, or can be left empty
    function createRequest(string description, uint256 value, address recipient) public isTokenHolder {
      require(value > 0);
      Request memory newRequest = Request({
          description: description,
          value: value,
          recipient: recipient,
          approvals: 0,
          complete: false
      });

      requests.push(newRequest);
      CreateRequest(description, value, requests.length - 1);
    }

    /// @notice Approve a request
    /// @dev Token holders can approve a request with their tokens for voting
    /// @param index the request index you want to approve
    /// @param numTokens amount of tokens you wish to vote with
    function approveRequest(uint index, uint256 numTokens) public isTokenHolder {
      require(numTokens > 0 && numTokens <= balances[msg.sender]);
      Request storage request = requests[index];
      require(!request.complete);

      request.approvals += numTokens;
      balances[msg.sender] = balances[msg.sender].sub(numTokens);
      balances[address(this)] = balances[address(this)].add(numTokens);
      Transfer(msg.sender, address(this), numTokens);
    }

    /// @notice Finalize a request
    /// @dev Owner can finalize a request, the request value must be less than or equal to the _charityBalance
    /// @param index the request index you want to approve
    function finalizeRequest(uint index) public isOwner {
      Request storage request = requests[index];

      require(request.approvals > 0);
      require(!request.complete);
      require(_charityBalance >= request.value);

      _charityBalance = _charityBalance.sub(request.value);
      request.complete = true;

      if (request.recipient == 0x0 || request.recipient == address(this)) {
        _owner.transfer(request.value);
      } else {
        request.recipient.transfer(request.value);
      }
      FinalizeRequest(index);
    }

    /// @notice Claim funds
    /// @dev This allows the owner to claim the funds after each round
    function claimFunds() public isOwner {
      require(_fundBalance > 0);
      _owner.transfer(_fundBalance);
      _fundBalance = 0;
    }

    /// @notice Pay for tickets by sending ETH to contract address
    /// @dev This calls buyTicket function with ether sent along
    function() public payable {
      buyTicket();
    }

    // /// @notice For testing purposes only
    // function destroy() isOwner public {
    //   selfdestruct(_owner);
    // }
}