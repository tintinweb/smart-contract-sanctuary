/**
 *Submitted for verification at BscScan.com on 2021-11-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function getOwner() external view returns (address);

    function transfer(address _to, uint256 _value) external returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function approve(address _spender, uint256 _value) external returns (bool success);

    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

pragma solidity ^0.8.3;

contract Dac {
    string public constant daoType = "DAC";

    string public name;

    string public symbol;

    address public immutable currency;

    uint256 public constant maxTeammates = 1000;

    address[] public teammates;

    uint256 public constant maxTotalSupply = 1e12;

    uint256 public totalSupply;

    uint8 public constant decimals = 0;

    uint256 public immutable governanceTokensPrice;

    bool public purchasePublic;

    bool public purchaseRuleFrozen;

    bool public halfToVote;

    bool public halfToVoteFrozen;

    bool public teammatesListFrozen = false;

    uint256 public votingDuration;

    bool public votingDurationFrozen;

    bool public mintable;

    bool public mintableFrozen;

    bool public burnable;

    bool public burnableFrozen;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    struct Voting {
        address contractAddress;
        bytes data;
        uint256 value;
        string comment;
        uint256 index;
        uint256 timestamp;
        bool isActivated;
        address[] signers;
    }

    Voting[] public votings;

    event VotingCreated(
        address contractAddress,
        bytes data,
        uint256 value,
        string comment,
        uint256 indexed index,
        uint256 timestamp
    );

    event VotingSigned(uint256 indexed index, address indexed signer, uint256 timestamp);

    event VotingActivated(uint256 indexed index, uint256 timestamp, bytes result);

    event Received(address, uint256);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    modifier teammatesOnly {
        bool isTeammate;

        for (uint256 i = 0; i < teammates.length; i++) {
            if (msg.sender == teammates[i]) {
                isTeammate = true;
                break;
            }
        }

        require(isTeammate);
        _;
    }

    modifier contractOnly {
        require(msg.sender == address(this));
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        address _currency,
        address[] memory _teammates,
        uint256 _totalSupply,
        uint256 _governanceTokensPrice,
        bool _purchasePublic,
        bool _halfToVote,
        uint256 _votingDuration
    ) {
        // Token Name
        name = _name;

        // Token Symbol
        symbol = _symbol;

        // Currency to Buy governanceTokens
        currency = _currency;

        // Teammates Setting
        require(_teammates.length <= maxTeammates, "Too Many Teammates");

        teammates = _teammates;

        // // Total Supply (P.S. decimals == 0)
        require(_totalSupply < maxTotalSupply, "Too Many governanceTokens");

        totalSupply = _totalSupply;

        // // governanceTokens Price
        governanceTokensPrice = _governanceTokensPrice;

        // // Who Can Buy governanceTokens (Teammates or Everyone)
        purchasePublic = _purchasePublic;

        // // Does it require that only Half of the Directors sign the transaction?
        halfToVote = _halfToVote;

        // // Duration of Voting
        require(
            _votingDuration == 2 hours || _votingDuration == 24 hours || _votingDuration == 72 hours,
            "Only 2 hours or 24 hours or 72 hours allowed"
        );

        votingDuration = _votingDuration;

        // Send All the governanceTokens to Organization
        balanceOf[address(this)] = _totalSupply;

        emit Transfer(address(0), address(this), _totalSupply);
    }

    function approve(address spender, uint256 amount) public returns (bool success) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount) public returns (bool success) {
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;

        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool success) {
        balanceOf[sender] -= amount;
        allowance[sender][msg.sender] -= amount;
        balanceOf[recipient] += amount;

        emit Transfer(sender, recipient, amount);
        return true;
    }

    function createVoting(
        address _contractAddress,
        bytes calldata _data,
        uint256 _value,
        string memory _comment
    ) external teammatesOnly returns (bool success) {
        address[] memory _signers;

        votings.push(
            Voting({
                contractAddress: _contractAddress,
                data: _data,
                value: _value,
                comment: _comment,
                index: votings.length,
                timestamp: block.timestamp,
                isActivated: false,
                signers: _signers
            })
        );

        emit VotingCreated(_contractAddress, _data, _value, _comment, votings.length - 1, block.timestamp);

        return true;
    }

    function signVoting(uint256 _index) external teammatesOnly returns (bool success) {
        // Didn't vote yet
        for (uint256 i = 0; i < votings[_index].signers.length; i++) {
            require(msg.sender != votings[_index].signers[i]);
        }

        // Time is not over
        require(block.timestamp <= votings[_index].timestamp + votingDuration);

        votings[_index].signers.push(msg.sender);

        emit VotingSigned(_index, msg.sender, block.timestamp);

        return true;
    }

    function activateVoting(uint256 _index) external {
        if (!halfToVote) {
            require(votings[_index].signers.length >= teammates.length);
        } else {
            require(votings[_index].signers.length > (teammates.length / 2));
        }

        require(!votings[_index].isActivated);

        address _contractToCall = votings[_index].contractAddress;

        bytes storage _data = votings[_index].data;

        uint256 _value = votings[_index].value;

        (bool b, bytes memory result) = _contractToCall.call{value: _value}(_data);

        require(b);

        votings[_index].isActivated = true;

        emit VotingActivated(_index, block.timestamp, result);
    }

    function addTeammate(address _newTeammate) public contractOnly returns (bool success) {
        require(!teammatesListFrozen);

        for (uint256 i = 0; i < teammates.length; i++) {
            require(_newTeammate != teammates[i]);
        }

        teammates.push(_newTeammate);

        return true;
    }

    function removeTeammate(address _teammateToRemove) public contractOnly returns (bool success) {
        require(!teammatesListFrozen);

        bool _found;
        uint256 _index;

        for (uint256 i = 0; i < teammates.length; i++) {
            if (_teammateToRemove == teammates[i]) {
                _found = true;
                _index = i;
                break;
            }
        }

        require(_found);

        teammates[_index] = teammates[teammates.length - 1];

        teammates.pop();

        return true;
    }

    function transferOfRights(address _oldTeammate, address _newTeammate) public contractOnly returns (bool success) {
        require(!teammatesListFrozen);

        for (uint256 i = 0; i < teammates.length; i++) {
            require(_newTeammate != teammates[i]);
        }

        bool _found;
        uint256 _index;

        for (uint256 i = 0; i < teammates.length; i++) {
            if (_oldTeammate == teammates[i]) {
                _found = true;
                _index = i;
                break;
            }
        }

        require(_found);

        teammates[_index] = _newTeammate;

        return true;
    }

    function freezeTeammatesListFrozen() public contractOnly returns (bool success) {
        teammatesListFrozen = true;

        return true;
    }

    function changePurchasePublic(bool _purchasePublic) public contractOnly returns (bool success) {
        require(!purchaseRuleFrozen);
        purchasePublic = _purchasePublic;

        return true;
    }

    function freezePurchaseRuleFrozen() public contractOnly returns (bool success) {
        purchaseRuleFrozen = true;

        return true;
    }

    function changeHalfToVote(bool _halfToVote) public contractOnly returns (bool success) {
        require(!halfToVoteFrozen);

        halfToVote = _halfToVote;

        return true;
    }

    function freezeHalfToVoteFrozen() public contractOnly returns (bool success) {
        halfToVoteFrozen = true;

        return true;
    }

    function changeVotingDuration(uint256 _votingDuration) public contractOnly returns (bool success) {
        require(!votingDurationFrozen);

        require(
            _votingDuration == 2 hours || _votingDuration == 24 hours || _votingDuration == 72 hours,
            "Only 2 hours or 24 hours or 72 hours allowed"
        );

        votingDuration = _votingDuration;

        return true;
    }

    function freezeVotingDuration() public contractOnly returns (bool success) {
        votingDurationFrozen = true;

        return true;
    }

    function changeMintable(bool _mintable) public contractOnly returns (bool success) {
        require(!mintableFrozen);

        mintable = _mintable;

        return true;
    }

    function freezeMintableFrozen() public contractOnly returns (bool success) {
        mintableFrozen = true;

        return true;
    }

    function changeBurnable(bool _burnable) public contractOnly returns (bool success) {
        require(!burnableFrozen);

        burnable = _burnable;

        return true;
    }

    function freezeBurnableFrozen() public contractOnly returns (bool success) {
        burnableFrozen = true;

        return true;
    }

    function mint(uint256 _amount) public contractOnly returns (bool success) {
        require(mintable && totalSupply + _amount < maxTotalSupply);

        totalSupply += _amount;

        balanceOf[address(this)] += _amount;

        return true;
    }

    function buyGovernanceTokens(uint256 _amount) external payable returns (bool success) {
        if (!purchasePublic) {
            bool _isTeammate;

            for (uint256 i = 0; i < teammates.length; i++) {
                if (msg.sender == teammates[i]) {
                    _isTeammate = true;
                    break;
                }
            }

            require(_isTeammate);
        }

        if (currency == 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c) {
            uint256 _amountIfBoughtWithCoins = msg.value / governanceTokensPrice;

            balanceOf[msg.sender] += _amountIfBoughtWithCoins;

            balanceOf[address(this)] -= _amountIfBoughtWithCoins;

            emit Transfer(address(this), msg.sender, _amountIfBoughtWithCoins);
        } else {
            IERC20 _currency = IERC20(currency);

            _currency.transferFrom(msg.sender, address(this), _amount * governanceTokensPrice);

            balanceOf[msg.sender] += _amount;

            balanceOf[address(this)] -= _amount;

            emit Transfer(address(this), msg.sender, _amount);
        }

        return true;
    }

    function burnGovernanceTokens(address[] memory _tokens) external returns (bool success) {
        require(burnable);

        require(!hasDuplicate(_tokens));

        for (uint256 i = 0; i < _tokens.length; i++) {
            require(_tokens[i] != address(this));
        }

        uint256 share = (1e18 * (totalSupply - balanceOf[address(this)])) / balanceOf[msg.sender];

        totalSupply -= balanceOf[msg.sender];

        balanceOf[msg.sender] = 0;

        bool _found;
        uint256 _index;

        for (uint256 i = 0; i < teammates.length; i++) {
            if (msg.sender == teammates[i]) {
                _found = true;
                _index = i;
                break;
            }
        }

        if (_found) {
            teammates[_index] = teammates[teammates.length - 1];

            teammates.pop();
        }

        uint256[] memory _tokenShares = new uint256[](_tokens.length);

        for (uint256 i = 0; i < _tokens.length; i++) {
            IERC20 _tokenToSend = IERC20(_tokens[i]);

            _tokenShares[i] = (1e18 * _tokenToSend.balanceOf(address(this))) / share;
        }

        payable(msg.sender).transfer((1e18 * address(this).balance) / share);

        for (uint256 i = 0; i < _tokens.length; i++) {
            IERC20 _tokenToSend = IERC20(_tokens[i]);

            bool b = _tokenToSend.transfer(msg.sender, _tokenShares[i]);

            require(b);
        }

        return true;
    }

    function hasDuplicate(address[] memory A) public pure returns (bool) {
        if (A.length == 0) {
            return false;
        } else {
            for (uint256 i = 0; i < A.length - 1; i++) {
                address current = A[i];
                for (uint256 j = i + 1; j < A.length; j++) {
                    if (current == A[j]) {
                        return true;
                    }
                }
            }
        }

        return false;
    }

    function getAllTeammates() external view returns (address[] memory) {
        return teammates;
    }

    function getAllVotings() external view returns (Voting[] memory) {
        return votings;
    }
}