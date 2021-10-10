/**
 *Submitted for verification at Etherscan.io on 2021-10-10
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.9;

interface IErc {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

interface IDexWallet {
    event Deposited(
        address operator,
        address depositFor,
        address token,
        uint256 amount
    );

    event Withdrawed(
        uint256 withdrawId,
        address operator,
        address withdrawTo,
        address token,
        uint256 amount
    );

    event TokenUpdated(address token, bool enabled);

    event ManagerUpdated(address manager, bool added);

    function getTokens() external view returns (address[] memory);

    function deposit(address token, uint256 amount) external payable;

    function depositFor(
        address depositFor,
        address token,
        uint256 amount
    ) external payable;

    function withdraw(
        uint256 withdrawId,
        address withdrawTo,
        address token,
        uint256 amount,
        uint256 expiresAt
    ) external;

    function balanceOf(address token) external view returns (uint256);

    function getOwner() external view returns (address);

    function getManagers() external view returns (address[] memory);
}

contract DexWallet is IDexWallet {
    // special "token" address for ETH:
    address private constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    uint256 private constant DEPOSIT_ENABLED = 1;
    uint256 private constant DEPOSIT_DISABLED = 2;

    // token -> deposit_status
    mapping(address => uint256) private tokens;
    address[] private tokenList;

    bool private paused;

    // owner:
    address private owner;

    // managers:
    address[] private managers;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    modifier onlyManager() {
        bool found = false;
        for (uint256 i = 0; i < managers.length; i++) {
            if (managers[i] == msg.sender) {
                found = true;
                break;
            }
        }
        require(found, "Caller is not manager");
        _;
    }

    modifier notPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    function setPaused(bool _paused) public onlyOwner {
        paused = _paused;
    }

    function setOwner(address _owner) public onlyOwner {
        require(_owner != address(0), "Zero address");
        owner = _owner;
    }

    function getOwner() public view override returns (address) {
        return owner;
    }

    function getManagers() public view override returns (address[] memory) {
        return managers;
    }

    function setManager(address _manager, bool _add) public onlyOwner {
        require(_manager != address(0), "Zero address");
        require(managers.length < 10, "Managers already full");
        if (_add) {
            // add manager:
            for (uint256 i = 0; i < managers.length; i++) {
                if (managers[i] == _manager) {
                    revert("Manager exist");
                }
            }
            managers.push(_manager);
        } else {
            // remove manager:
            bool found = false;
            uint256 index;
            for (uint256 i = 0; i < managers.length; i++) {
                if (managers[i] == _manager) {
                    found = true;
                    index = i;
                    break;
                }
            }
            require(found, "Manager not found");
            for (uint256 i = index; i < managers.length - 1; i++) {
                managers[i] = managers[i + 1];
            }
            managers.pop();
        }
        emit ManagerUpdated(_manager, _add);
    }

    function addToken(address _token) public onlyOwner {
        require(_token != ETH, "No need add ETH");
        require(tokens[_token] == 0, "Token exist");
        tokens[_token] = DEPOSIT_DISABLED;
        tokenList.push(_token);
        emit TokenUpdated(_token, true);
    }

    function setToken(address _token, bool _enabled) public onlyOwner {
        require(_token != ETH, "No need add ETH");
        require(tokens[_token] != 0, "Token not found");
        tokens[_token] = _enabled ? DEPOSIT_ENABLED : DEPOSIT_DISABLED;
        emit TokenUpdated(_token, _enabled);
    }

    function canDeposit(address _token) public view returns (bool) {
        return tokens[_token] == DEPOSIT_ENABLED;
    }

    function getTokens() public view override returns (address[] memory) {
        return tokenList;
    }

    function balanceOf(address _token) public view override returns (uint256) {
        if (_token == ETH) {
            return address(this).balance;
        }
        return IErc(_token).balanceOf(address(this));
    }

    function deposit(address _token, uint256 _amount)
        public
        payable
        override
        notPaused
    {
        depositFor(msg.sender, _token, _amount);
    }

    function depositFor(
        address _depositFor,
        address _token,
        uint256 _amount
    ) public payable override notPaused {
        require(_depositFor != address(0), "Cannot deposit for zero address");
        require(_amount > 0, "Cannot deposit zero amount");
        if (_token == ETH) {
            require(msg.value == _amount, "Unexpected Ether paid");
        } else {
            require(msg.value == 0, "Cannot pay Ether");
            require(
                tokens[_token] == DEPOSIT_ENABLED,
                "Token cannot be deposit"
            );
            bool r = IErc(_token).transferFrom(
                msg.sender,
                address(this),
                _amount
            );
            require(r, "TransferFrom failed");
        }
        emit Deposited(msg.sender, _depositFor, _token, _amount);
    }

    function withdraw(
        uint256 _withdrawId,
        address _withdrawTo,
        address _token,
        uint256 _amount,
        uint256 _expiresAt
    ) public override onlyManager notPaused {
        require(_expiresAt > block.timestamp, "Tx expired");
        require(_withdrawTo != address(0), "Cannot withdraw to zero address");
        if (_token == ETH) {
            (bool sent, bytes memory d) = _withdrawTo.call{value: _amount}("");
            require(sent, "Failed to withdraw Ether");
        } else {
            require(tokens[_token] != 0, "Token cannot be withdrawed");
            IErc(_token).transferFrom(address(this), _withdrawTo, _amount);
        }
        emit Withdrawed(_withdrawId, msg.sender, _withdrawTo, _token, _amount);
    }

    function emergencyTransfer(address _token) public onlyOwner {
        require(_token != address(0), "Zero token address");
        if (_token == ETH) {
            uint256 amount = address(this).balance;
            (bool sent, bytes memory d) = owner.call{value: amount}("");
            require(sent, "Failed to emergency transfer Ether");
        } else {
            // do not check token so owner can transfer any erc:
            IErc erc = IErc(_token);
            uint256 amount = erc.balanceOf(address(this));
            erc.transferFrom(address(this), owner, amount);
        }
    }
}