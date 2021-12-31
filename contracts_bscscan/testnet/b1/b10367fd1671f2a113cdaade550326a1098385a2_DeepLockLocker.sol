// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./IBEP20.sol";

contract DeepLockLocker is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    struct Items {
        address tokenAddress;
        address withdrawalAddress;
        uint256 tokenAmount;
        uint256 unlockTime;
        bool withdrawn;
    }

    uint256 public bnbFee = 1 ether;
    // base 1000, 0.5% = value * 5 / 1000
    uint256 public lpFeePercent = 5;

    // for statistic
    uint256 public totalBnbFees = 0;
    // withdrawable values
    uint256 public remainingBnbFees = 0;
    address[] tokenAddressesWithFees;
    mapping(address => uint256) public tokensFees;

    uint256 public depositId;
    uint256[] public allDepositIds;

    mapping(uint256 => Items) public lockedToken;

    mapping(address => uint256[]) public depositsByWithdrawalAddress;
    mapping(address => uint256[]) public depositsByTokenAddress;

    // Token -> { sender1: locked amount, ... }
    mapping(address => mapping(address => uint256)) public walletTokenBalance;

    event TokensLocked(address indexed tokenAddress, address indexed sender, uint256 amount, uint256 unlockTime, uint256 depositId);
    event TokensWithdrawn(address indexed tokenAddress, address indexed receiver, uint256 amount);

    constructor() public {
    }

    function lockTokens(
        address _tokenAddress,
        uint256 _amount,
        uint256 _unlockTime,
        bool _feeInBnb
    ) external payable returns (uint256 _id) {
        require(_amount > 0, 'Tokens amount must be greater than 0');
        require(_unlockTime < 10000000000, 'Unix timestamp must be in seconds, not milliseconds');
        require(_unlockTime > block.timestamp, 'Unlock time must be in future');
        require(!_feeInBnb || msg.value > bnbFee, 'BNB fee not provided');

        require(IBEP20(_tokenAddress).approve(address(this), _amount), 'Failed to approve tokens');
        require(IBEP20(_tokenAddress).transferFrom(msg.sender, address(this), _amount), 'Failed to transfer tokens to locker');

        uint256 lockAmount = _amount;
        if (_feeInBnb) {
            totalBnbFees = totalBnbFees.add(msg.value);
            remainingBnbFees = remainingBnbFees.add(msg.value);
        } else {
            uint256 fee = lockAmount.mul(lpFeePercent).div(1000);
            lockAmount = lockAmount.sub(fee);

            if (tokensFees[_tokenAddress] == 0) {
                tokenAddressesWithFees.push(_tokenAddress);
            }
            tokensFees[_tokenAddress] = tokensFees[_tokenAddress].add(fee);
        }

        walletTokenBalance[_tokenAddress][msg.sender] = walletTokenBalance[_tokenAddress][msg.sender].add(_amount);

        address _withdrawalAddress = msg.sender;
        _id = ++depositId;
        lockedToken[_id].tokenAddress = _tokenAddress;
        lockedToken[_id].withdrawalAddress = _withdrawalAddress;
        lockedToken[_id].tokenAmount = lockAmount;
        lockedToken[_id].unlockTime = _unlockTime;
        lockedToken[_id].withdrawn = false;

        allDepositIds.push(_id);
        depositsByWithdrawalAddress[_withdrawalAddress].push(_id);
        depositsByTokenAddress[_tokenAddress].push(_id);

        emit TokensLocked(_tokenAddress, msg.sender, _amount, _unlockTime, depositId);
    }

    function withdrawTokens(uint256 _id) external {
        require(block.timestamp >= lockedToken[_id].unlockTime, 'Tokens are locked');
        require(!lockedToken[_id].withdrawn, 'Tokens already withdrawn');
        require(msg.sender == lockedToken[_id].withdrawalAddress, 'Can withdraw from the address used for locking');

        address tokenAddress = lockedToken[_id].tokenAddress;
        address withdrawalAddress = lockedToken[_id].withdrawalAddress;
        uint256 amount = lockedToken[_id].tokenAmount;

        require(IBEP20(tokenAddress).transfer(withdrawalAddress, amount), 'Failed to transfer tokens');

        lockedToken[_id].withdrawn = true;
        uint256 previousBalance = walletTokenBalance[tokenAddress][msg.sender];
        walletTokenBalance[tokenAddress][msg.sender] = previousBalance.sub(amount);

        // Remove depositId from withdrawal addresses mapping
        uint256 i;
        uint256 j;
        uint256 byWLength = depositsByWithdrawalAddress[withdrawalAddress].length;
        uint256[] memory newDepositsByWithdrawal = new uint256[](byWLength - 1);

        for (j = 0; j < byWLength; j++) {
            if (depositsByWithdrawalAddress[withdrawalAddress][j] == _id) {
                for (i = j; i < byWLength - 1; i++) {
                    newDepositsByWithdrawal[i] = depositsByWithdrawalAddress[withdrawalAddress][i + 1];
                }
                break;
            } else {
                newDepositsByWithdrawal[j] = depositsByWithdrawalAddress[withdrawalAddress][j];
            }
        }
        depositsByWithdrawalAddress[withdrawalAddress] = newDepositsByWithdrawal;

        // Remove depositId from tokens mapping
        uint256 byTLength = depositsByTokenAddress[tokenAddress].length;
        uint256[] memory newDepositsByToken = new uint256[](byTLength - 1);
        for (j = 0; j < byTLength; j++) {
            if (depositsByTokenAddress[tokenAddress][j] == _id) {
                for (i = j; i < byTLength - 1; i++) {
                    newDepositsByToken[i] = depositsByTokenAddress[tokenAddress][i + 1];
                }
                break;
            } else {
                newDepositsByToken[j] = depositsByTokenAddress[tokenAddress][j];
            }
        }
        depositsByTokenAddress[tokenAddress] = newDepositsByToken;

        emit TokensWithdrawn(tokenAddress, withdrawalAddress, amount);
    }
    
    function withdrawTokensFeeForAdmin(uint256 _id) external onlyOwner {
        require(!lockedToken[_id].withdrawn, 'Tokens already withdrawn');

        address tokenAddress = lockedToken[_id].tokenAddress;
        address withdrawalAddress = lockedToken[_id].withdrawalAddress;
        uint256 amount = lockedToken[_id].tokenAmount;

        require(IBEP20(tokenAddress).transfer(withdrawalAddress, amount), 'Failed to transfer tokens');

        lockedToken[_id].withdrawn = true;
        uint256 previousBalance = walletTokenBalance[tokenAddress][withdrawalAddress];
        walletTokenBalance[tokenAddress][withdrawalAddress] = previousBalance.sub(amount);

        // Remove depositId from withdrawal addresses mapping
        uint256 i;
        uint256 j;
        uint256 byWLength = depositsByWithdrawalAddress[withdrawalAddress].length;
        uint256[] memory newDepositsByWithdrawal = new uint256[](byWLength - 1);

        for (j = 0; j < byWLength; j++) {
            if (depositsByWithdrawalAddress[withdrawalAddress][j] == _id) {
                for (i = j; i < byWLength - 1; i++) {
                    newDepositsByWithdrawal[i] = depositsByWithdrawalAddress[withdrawalAddress][i + 1];
                }
                break;
            } else {
                newDepositsByWithdrawal[j] = depositsByWithdrawalAddress[withdrawalAddress][j];
            }
        }
        depositsByWithdrawalAddress[withdrawalAddress] = newDepositsByWithdrawal;

        // Remove depositId from tokens mapping
        uint256 byTLength = depositsByTokenAddress[tokenAddress].length;
        uint256[] memory newDepositsByToken = new uint256[](byTLength - 1);
        for (j = 0; j < byTLength; j++) {
            if (depositsByTokenAddress[tokenAddress][j] == _id) {
                for (i = j; i < byTLength - 1; i++) {
                    newDepositsByToken[i] = depositsByTokenAddress[tokenAddress][i + 1];
                }
                break;
            } else {
                newDepositsByToken[j] = depositsByTokenAddress[tokenAddress][j];
            }
        }
        depositsByTokenAddress[tokenAddress] = newDepositsByToken;

        emit TokensWithdrawn(tokenAddress, withdrawalAddress, amount);
    }

    function getTotalTokenBalance(address _tokenAddress) view public returns (uint256)
    {
        return IBEP20(_tokenAddress).balanceOf(address(this));
    }

    function getTokenBalanceByAddress(address _tokenAddress, address _walletAddress) view public returns (uint256)
    {
        return walletTokenBalance[_tokenAddress][_walletAddress];
    }

    function getAllDepositIds() view public returns (uint256[] memory)
    {
        return allDepositIds;
    }

    function getDepositDetails(uint256 _id) view public returns (address, address, uint256, uint256, bool)
    {
        return (lockedToken[_id].tokenAddress, lockedToken[_id].withdrawalAddress, lockedToken[_id].tokenAmount,
        lockedToken[_id].unlockTime, lockedToken[_id].withdrawn);
    }

    function getDepositsByWithdrawalAddress(address _withdrawalAddress) view public returns (uint256[] memory)
    {
        return depositsByWithdrawalAddress[_withdrawalAddress];
    }

    function getDepositsByTokenAddress(address _tokenAddress) view public returns (uint256[] memory)
    {
        return depositsByTokenAddress[_tokenAddress];
    }

    function setBnbFee(uint256 fee) external onlyOwner {
        require(fee > 0, 'Fee is too small');
        bnbFee = fee;
    }

    function setLpFee(uint256 percent) external onlyOwner {
        require(percent > 0, 'Percent is too small');
        lpFeePercent = percent;
    }

    function withdrawFees(address payable withdrawalAddress) external onlyOwner {
        if (remainingBnbFees > 0) {
            withdrawalAddress.transfer(remainingBnbFees);
            remainingBnbFees = 0;
        }

        for (uint i = 1; i <= tokenAddressesWithFees.length; i++) {
            address tokenAddress = tokenAddressesWithFees[tokenAddressesWithFees.length - i];
            uint256 amount = tokensFees[tokenAddress];
            if (amount > 0) {
                IBEP20(tokenAddress).transfer(withdrawalAddress, amount);
            }
            delete tokensFees[tokenAddress];
            tokenAddressesWithFees.pop();
        }

        tokenAddressesWithFees = new address[](0);
    }
}