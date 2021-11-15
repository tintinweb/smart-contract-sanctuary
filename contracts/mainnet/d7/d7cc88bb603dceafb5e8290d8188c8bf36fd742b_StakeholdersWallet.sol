// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;


interface IERC20Min {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

// It distributes ERC-20 tokens from its balance to stakeholders
contract StakeholdersWallet {

    struct StakeHolder {
        address wallet;
        uint32 stake;
    }

    // Reserved storage space for possible proxies' use
    uint256[100] __gap;

    // Sum of stakes scaled by 1e4
    uint256 public stakesSum;

    // Mapping from stakeholder ID (index starting from 1) to stakeholder data
    mapping(uint256 => StakeHolder) public stakeholders;
    uint public numOfStakes;

    bool private _notEntered;

    event Stakeholder(uint256 indexed id, address wellet, uint256 stake);
    event WalletUpdate(uint256 id, address newWallet);
    event Distributed(uint256 indexed id, address token, uint256 amount);

    constructor (StakeHolder[] memory _stakeholders) public
    {
        _notEntered = true;

        // To minimize 'out of gas' risk on distributions
        require(_stakeholders.length <= 20, "too many stakeholders");

        for (uint i = 0 ; i < _stakeholders.length; i++) {
            _revertZeroAddress(_stakeholders[i].wallet);
            require(
                _stakeholders[i].stake != 0 && _stakeholders[i].stake < 2**32,
                "invalid stake"
            );

            stakeholders[i + 1] = _stakeholders[i];

            // can't overflow (no safeMath needed)
            numOfStakes = numOfStakes + 1;
            stakesSum = stakesSum + _stakeholders[i].stake;

            emit Stakeholder(i + 1, _stakeholders[i].wallet, _stakeholders[i].stake);
        }
    }

    // Distribute this contract balance between stakeholders (anyone can call)
    function distribute(IERC20Min token) external {
        require(_notEntered, "reentrant call");
        _notEntered = false;

        _revertZeroAddress(address(token));
        require(stakesSum != 0, "no stakes to distribute between");

        uint256 balance = token.balanceOf(address(this));
        // division by zero impossible
        uint256 scaledShare = _mul(balance, 1e4) / stakesSum;

        require(scaledShare != 0, "nothing to distribute");

        for (uint256 i = 1; i <= numOfStakes; i++) {
            StakeHolder memory holder = stakeholders[i];

            uint256 amount = _mul(scaledShare, holder.stake) / 1e4;
            _safeTransfer(token, holder.wallet, amount);

            emit Distributed(i, address(token), amount);
        }

        _notEntered = true;
    }

    // Update wallet address of a stakeholder (only the stakeholder may call)
    function updateWallet(uint stakeholderID, address newWallet) external {
        require(stakeholders[stakeholderID].wallet == msg.sender, "unauthorized");
        _revertZeroAddress(newWallet);
        stakeholders[stakeholderID].wallet = newWallet;
        emit WalletUpdate(stakeholderID, newWallet);
    }

    // Borrowed from SafeERC20 by @openzeppelin
    function _safeTransfer(IERC20Min token, address to, uint256 value) internal {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );

        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: operation did not succeed"
            );
        }
    }

    function _mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) return 0;
        c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
    }

    function _revertZeroAddress(address _address) private pure {
        require(_address != address(0), "zero address");
    }
}

