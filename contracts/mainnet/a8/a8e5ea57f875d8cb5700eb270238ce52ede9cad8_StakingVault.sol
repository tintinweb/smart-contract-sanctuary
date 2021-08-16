// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./TransferHelper.sol";

interface Token {
    function decimals() external view returns (uint256);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function burn(uint256 _value) external returns (bool success);
}

contract StakingVault is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    struct VaultInfo {
        uint256 id;
        uint256 poolSize;
        uint256 minimumAmount;
        uint256 maturityPeriod; // in timemillseconds
        uint256 APY; // in 10^2
        uint256 earlyWithDrawTime; // in timemillseconds
        uint256 withDrawPenality; // in 10^2
        uint256 investmentPeriod; // in timemillseconds
        uint256 startTimeStamp;
        uint256 userAmountAdded;
        string name;
        uint256 maximumAmount;
    }
    mapping(uint256 => VaultInfo) public VaultMapping;
    uint256 public vaultId;
    address public XIVTokenContractAddress =
        0x44f262622248027f8E2a8Fb1090c4Cf85072392C; //XIV contract address
    struct userVaultInfo {
        uint256 investMentVaultId;
        uint256 investmentAmount;
        uint256 maturityPeriod; // in timemillseconds
        uint256 APY; // in 10^2
        uint256 earlyWithDrawTime; // in timemillseconds
        uint256 withDrawPenality; // in 10^2
        uint256 startTimeStamp;
        uint256 stakingTimeStamp;
        string name;
        bool isActive;
    }
    mapping(address => mapping(uint256 => userVaultInfo)) public userMapping;
    uint256 oneYear;
    mapping(uint256 => bool) public addedToColdmapping;

    bool isInitialized;

    function initialize(address owner, address _XIVTokenContractAddress)
        public
    {
        require(!isInitialized, "Already initialized");
        _setOwner(owner);
        isInitialized = true;
        XIVTokenContractAddress = _XIVTokenContractAddress;
        oneYear = 365 days;
    }

    function createVault(
        uint256 _poolSize,
        uint256 _maturityPeriod,
        uint256 _minimumAmount,
        uint256 _maximumAmount,
        uint256 _APY,
        uint256 _earlyWithDrawTime,
        uint256 _withDrawPenality,
        uint256 _investmentPeriod,
        string memory _name
    ) external onlyOwner {
        vaultId = vaultId.add(1);
        require(
            _maturityPeriod > _earlyWithDrawTime,
            "Early withdraw > Maturity"
        );
        require(
            _earlyWithDrawTime > _investmentPeriod,
            "Investment period > Early withdraw"
        );
        VaultInfo memory vInfo = VaultInfo({
            id: vaultId,
            poolSize: _poolSize,
            minimumAmount: _minimumAmount,
            maximumAmount: _maximumAmount,
            maturityPeriod: _maturityPeriod,
            APY: _APY,
            earlyWithDrawTime: _earlyWithDrawTime,
            withDrawPenality: _withDrawPenality,
            investmentPeriod: _investmentPeriod,
            startTimeStamp: block.timestamp,
            userAmountAdded: 0,
            name: _name
        });
        VaultMapping[vaultId] = vInfo;
    }

    function updateVault(
        uint256 id,
        uint256 _poolSize,
        uint256 _maturityPeriod,
        uint256 _minimumAmount,
        uint256 _maximumAmount,
        uint256 _APY,
        uint256 _earlyWithDrawTime,
        uint256 _withDrawPenality,
        uint256 _investmentPeriod,
        string memory _name
    ) external onlyOwner {
        require(
            (block.timestamp >
                (
                    VaultMapping[id].startTimeStamp.add(
                        VaultMapping[id].maturityPeriod
                    )
                )),
            "Wait till maturity."
        );
        require(
            VaultMapping[id].userAmountAdded == 0,
            "Repay for this vault."
        );
        require(
            _maturityPeriod > _earlyWithDrawTime,
            "Early withdraw > Maturity"
        );
        require(
            _earlyWithDrawTime > _investmentPeriod,
            "Investment period > Early withdraw"
        );
        VaultMapping[id].poolSize = _poolSize;
        VaultMapping[id].minimumAmount = _minimumAmount;
        VaultMapping[id].maximumAmount = _maximumAmount;
        VaultMapping[id].maturityPeriod = _maturityPeriod;
        VaultMapping[id].APY = _APY;
        VaultMapping[id].earlyWithDrawTime = _earlyWithDrawTime;
        VaultMapping[id].withDrawPenality = _withDrawPenality;
        VaultMapping[id].investmentPeriod = _investmentPeriod;
        VaultMapping[id].name = _name;
        VaultMapping[id].startTimeStamp = 0;
    }

    function activateVault(uint256 _activeVaultId) external onlyOwner {
        require(vaultId >= _activeVaultId, "Enter valid vault.");
        require(
            (block.timestamp >
                (
                    VaultMapping[_activeVaultId].startTimeStamp.add(
                        VaultMapping[_activeVaultId].maturityPeriod
                    )
                )),
            "re-activation allowed after maturity."
        );
        require(
            VaultMapping[_activeVaultId].userAmountAdded == 0,
            "Repay for this vault."
        );
        VaultMapping[_activeVaultId].startTimeStamp = block.timestamp;
        VaultMapping[_activeVaultId].userAmountAdded = 0;
    }

    function fillPool(uint256 amount, uint256 _VaultId) external nonReentrant {
        VaultInfo memory vInfo = VaultMapping[_VaultId];
        require(
            block.timestamp <=
                (vInfo.startTimeStamp.add(vInfo.investmentPeriod)),
            "Pool filling is closed."
        );
        require(vInfo.minimumAmount <= (amount), "Enter more Amount.");
        require(vInfo.maximumAmount >= (amount), "Enter less Amount.");
        require(
            vInfo.poolSize >= (vInfo.userAmountAdded.add(amount)),
            "Add less amount."
        );
        Token tokenObj = Token(XIVTokenContractAddress);
        //check if user has balance
        require(
            tokenObj.balanceOf(msg.sender) >= amount,
            "Insufficient XIV balance"
        );
        //check if user has provided allowance
        require(
            tokenObj.allowance(msg.sender, address(this)) >= amount,
            "Provide token approval to contract"
        );
        if (
            (userMapping[msg.sender][_VaultId].startTimeStamp !=
                vInfo.startTimeStamp) &&
            (userMapping[msg.sender][_VaultId].isActive)
        ) {
            require(
                false,
                "Claim current investment before staking."
            );
        }
        TransferHelper.safeTransferFrom(
            XIVTokenContractAddress,
            msg.sender,
            address(this),
            amount
        );
        userVaultInfo memory userVInfo = userVaultInfo({
            investMentVaultId: vInfo.id,
            investmentAmount: userMapping[msg.sender][_VaultId]
                .investmentAmount
                .add(amount),
            maturityPeriod: vInfo.maturityPeriod,
            APY: vInfo.APY,
            earlyWithDrawTime: vInfo.earlyWithDrawTime,
            withDrawPenality: vInfo.withDrawPenality,
            startTimeStamp: vInfo.startTimeStamp,
            stakingTimeStamp: block.timestamp,
            name: vInfo.name,
            isActive: true
        });
        userMapping[msg.sender][_VaultId] = userVInfo;
        VaultMapping[_VaultId].userAmountAdded = (
            VaultMapping[_VaultId].userAmountAdded
        ).add(amount);
    }

    function transferToColdWallet(address walletAddress, uint256 _VaultId)
        external
        onlyOwner
    {
        VaultInfo memory vInfo = VaultMapping[_VaultId];
        require(
            !(addedToColdmapping[_VaultId]),
            "Already Added to Cold Wallet"
        );
        Token tokenObj = Token(XIVTokenContractAddress);
        require(
            tokenObj.balanceOf(address(this)) >= vInfo.userAmountAdded,
            "Insufficient XIV balance"
        );
        require(
            block.timestamp >
                ((vInfo.startTimeStamp).add(vInfo.investmentPeriod)),
            "Investment Period is active."
        );
        addedToColdmapping[_VaultId] = true;
        TransferHelper.safeTransfer(
            XIVTokenContractAddress,
            walletAddress,
            vInfo.userAmountAdded
        );
    }

    function calculateReturnValue(uint256 _vaultId)
        public
        view
        returns (uint256)
    {
        VaultInfo memory vInfo = VaultMapping[_vaultId];
        return (
            vInfo.userAmountAdded.add(
                (
                    (vInfo.APY).mul(vInfo.userAmountAdded).mul(
                        vInfo.maturityPeriod
                    )
                ).div((oneYear).mul(10**4))
            )
        );
    }

    function transferToContract(uint256 _vaultId, uint256 _amount)
        external
        onlyOwner
    {
        uint256 calculateAmount = calculateReturnValue(_vaultId);
        require(
            VaultMapping[_vaultId].userAmountAdded > 0,
            "Vault not valid to recieve funds"
        );
        require(_amount >= calculateAmount, "Enter more amount.");
        Token tokenObj = Token(XIVTokenContractAddress);
        //check if user has balance
        require(
            tokenObj.balanceOf(msg.sender) >= _amount,
            "Insufficient XIV balance"
        );
        //check if user has provided allowance
        require(
            tokenObj.allowance(msg.sender, address(this)) >= _amount,
            "Provide token approval to contract"
        );
        TransferHelper.safeTransferFrom(
            XIVTokenContractAddress,
            msg.sender,
            address(this),
            _amount
        );
        addedToColdmapping[_vaultId] = false;
        VaultMapping[_vaultId].userAmountAdded = 0;
    }

    function claimAmount(uint256 _VaultId) external nonReentrant {
        Token tokenObj = Token(XIVTokenContractAddress);
        userVaultInfo memory uVaultInfo = userMapping[msg.sender][_VaultId];
        require(userMapping[msg.sender][_VaultId].isActive, "Already claimed.");
        uint256 userClaimAmount;
        uint256 investmentAmount;
        require(
            block.timestamp >
                (uVaultInfo.startTimeStamp.add(uVaultInfo.earlyWithDrawTime)),
            "Can not claim too early."
        );
        require(
            (uVaultInfo.earlyWithDrawTime > 0) ||
                (block.timestamp >
                    (uVaultInfo.startTimeStamp.add(uVaultInfo.maturityPeriod))),
            "Can not claim too early."
        );
        if (
            block.timestamp >
            (uVaultInfo.startTimeStamp.add(uVaultInfo.earlyWithDrawTime)) &&
            block.timestamp <
            (uVaultInfo.startTimeStamp.add(uVaultInfo.maturityPeriod))
        ) {
            uint256 panelty = (
                uVaultInfo.withDrawPenality.mul(uVaultInfo.investmentAmount)
            ).div(10**4);
            userClaimAmount = uVaultInfo.investmentAmount.sub(panelty);
            investmentAmount=userClaimAmount;
        } else {
            userClaimAmount = uVaultInfo.investmentAmount.add(
                (
                    uVaultInfo.APY.mul(uVaultInfo.investmentAmount).mul(
                        uVaultInfo.maturityPeriod
                    )
                ).div((oneYear).mul(10**4))
            );
            investmentAmount=uVaultInfo.investmentAmount;
        }
        require(
            tokenObj.balanceOf(address(this)) >= userClaimAmount,
            "The contract does not have enough XIV balance."
        );
        TransferHelper.safeTransfer(
            XIVTokenContractAddress,
            msg.sender,
            userClaimAmount
        );
        if (VaultMapping[uVaultInfo.investMentVaultId].userAmountAdded > 0) {
            VaultMapping[uVaultInfo.investMentVaultId]
                .userAmountAdded = VaultMapping[uVaultInfo.investMentVaultId]
                .userAmountAdded
                .sub(investmentAmount);
        }
        userMapping[msg.sender][_VaultId].isActive = false;
        userMapping[msg.sender][_VaultId].investmentAmount = 0;
    }

    function makeTransfer(
        address payable[] memory addressArray,
        uint256[] memory amountArray
    ) external onlyOwner {
        require(
            addressArray.length == amountArray.length,
            "Arrays must be of same size."
        );
        Token tokenInstance = Token(XIVTokenContractAddress);
        for (uint256 i = 0; i < addressArray.length; i++) {
            require(
                tokenInstance.balanceOf(address(this)) >= amountArray[i],
                "contract has insufficient token balance."
            );
            TransferHelper.safeTransfer(
                XIVTokenContractAddress,
                addressArray[i],
                amountArray[i]
            );
        }
    }

    function updateXIVAddress(address _XIVTokenContractAddress)
        external
        onlyOwner
    {
        XIVTokenContractAddress = _XIVTokenContractAddress;
    }
}