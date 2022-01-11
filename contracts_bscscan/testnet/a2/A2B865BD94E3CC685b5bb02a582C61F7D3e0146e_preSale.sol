pragma solidity ^0.8.9;
// SPDX-License-Identifier: MIT

import "./Interfaces/IPreSale.sol";

contract preSale {
    using SafeMath for uint256;
    using SafeMath for uint256;

    address payable public admin;
    address payable public tokenOwner;
    address public deployer;
    IERC20 public coin;
    IERC20 public token;
    IPancakeRouter02 public routerAddress;

    uint256 public userFee;
    uint256 public projectCoinFee;
    uint256 public projectTokenFee;
    uint256 public adminFeeCounter;
    uint256 public liquidityPercent;
    uint256 public vestingPercent;
    uint256 public tokenPricePublic;
    uint256 public tokenPricePrivate;
    uint256 public tokenPriceSeed;
    uint256 public preSaleEndTime;
    uint256 public minAmount;
    uint256 public maxAmount;
    uint256 public vestingTimeStep;
    uint256 public hardCapPublic;
    uint256 public hardCapPrivate;
    uint256 public hardCapSeed;
    uint256 public softCapPublic;
    uint256 public softCapPrivate;
    uint256 public softCapSeed;
    uint256 public listingPrice;
    uint256 public totalTokenPublic;
    uint256 public totalTokenPrivate;
    uint256 public totalTokenSeed;
    uint256 public saleType;
    uint256 public currentClaimCycle;
    uint256 public vestingTime;
    uint256 public totalUser;
    uint256 public amountRaisedPublic;
    uint256 public amountRaisedPrivate;
    uint256 public amountRaisedSeed;
    uint256 public soldTokensPublic;
    uint256 public soldTokensPrivate;
    uint256 public soldTokensSeed;
    uint256 public tokenOwnerProfitPublic;
    uint256 public tokenOwnerProfitPrivate;
    uint256 public tokenOwnerProfitSeed;
    uint256 public voteUp;
    uint256 public voteDown;
    uint256 public votingStartTime;
    uint256 public votingEndTime;
    uint256 public currentVotingCycle;

    bool public allow;
    bool public profitClaim;
    bool public votingStatus;
    bool public canClaim;
    bool public presaleEnd;
    bool public publicRefundClaimed;
    bool public privateRefundClaimed;
    bool public seedRefundClaimed;

    struct VotingData {
        bool vote;
        bool voteCasted;
    }

    mapping(address => bool) public whiteListPrivate;
    mapping(address => bool) public whiteListSeed;
    mapping(address => uint256) public coinBalancePublic;
    mapping(address => uint256) public tokenBalancePublic;
    mapping(address => uint256) public coinBalancePrivate;
    mapping(address => uint256) public tokenBalancePrivate;
    mapping(address => uint256) public coinBalanceSeed;
    mapping(address => uint256) public tokenBalanceSeed;
    mapping(address => uint256) public activeClaimAmountCoinPublic;
    mapping(address => uint256) public activeClaimAmountTokenPublic;
    mapping(address => uint256) public activeClaimAmountCoinPrivate;
    mapping(address => uint256) public activeClaimAmountTokenPrivate;
    mapping(address => uint256) public activeClaimAmountCoinSeed;
    mapping(address => uint256) public activeClaimAmountTokenSeed;
    mapping(address => uint256) public claimCount;
    mapping(address => mapping(uint256 => VotingData)) internal usersVoting;

    modifier onlyAdmin() {
        require(msg.sender == admin, "PRESALE: Not an admin");
        _;
    }

    modifier onlyTokenOwner() {
        require(msg.sender == tokenOwner, "PRESALE: Not a token owner");
        _;
    }

    modifier allowed() {
        require(allow, "PRESALE: Not allowed");
        _;
    }

    event TokenBought(
        address indexed user,
        uint256 indexed numberOfTokens,
        uint256 indexed amountBusd
    );

    event TokenClaimed(address indexed user, uint256 indexed numberOfTokens);

    event CoinClaimed(address indexed user, uint256 indexed numberOfCoins);

    event TokenUnSold(address indexed user, uint256 indexed numberOfTokens);

    constructor() {
        deployer = msg.sender;
        voteUp = 1;
    }

    /*

    _presaleTime,
    _vestingTime,
    _vestingPercent,
    _liquidityPercent,
    _minAmount,
    _maxAmount,
    _tokenPricePublic,
    _hardCapPublic,
    _softCapPublic,
    _tokenPricePrivate,
    _hardCapPrivate,
    _softCapPrivate,
    _tokenPriceSeed,
    _hardCapSeed,
    _softCapSeed,
    _listingPrice,
    _totalTokenPublic
    _totalTokenPrivate
    _totalTokenSeed

*/

    // called once by the deployer contract at time of deployment
    function initialize(
        address _admin,
        address _tokenOwner,
        IERC20 _coin,
        IERC20 _token,
        address _routerAddress,
        uint256 _userFee,
        uint256 _projectCoinFee,
        uint256 _projectTokenFee,
        uint256[] memory _data
    ) external {
        require(msg.sender == deployer, "PRESALE: FORBIDDEN"); // sufficient check
        admin = payable(_admin);
        tokenOwner = payable(_tokenOwner);
        coin = _coin;
        token = _token;
        routerAddress = IPancakeRouter02(_routerAddress);
        userFee = _userFee;
        projectCoinFee = _projectCoinFee;
        projectTokenFee = _projectTokenFee;
        preSaleEndTime = _data[0];
        vestingTimeStep = _data[1];
        vestingPercent = _data[2];
        liquidityPercent = _data[3];
        minAmount = _data[4];
        maxAmount = _data[5];
        tokenPricePublic = _data[6];
        hardCapPublic = _data[7];
        softCapPublic = _data[8];
        tokenPricePrivate = _data[9];
        hardCapPrivate = _data[10];
        softCapPrivate = _data[11];
        tokenPriceSeed = _data[12];
        hardCapSeed = _data[13];
        softCapSeed = _data[14];
        listingPrice = _data[15];
        totalTokenPublic = _data[16];
        totalTokenPrivate = _data[17];
        totalTokenSeed = _data[18];
    }

    receive() external payable {}

    // to buy token during preSale time => for web3 use
    function buyToken(uint256 _type, uint256 _amount) public allowed {
        require(block.timestamp < preSaleEndTime, "PRESALE: Time over"); // time check
        coin.transferFrom(msg.sender, address(this), _amount);
        uint256 numberOfTokens;
        uint256 _fee;

        if (_type == 1) {
            require(
                _amount >= minAmount &&
                    coinBalancePublic[msg.sender].add(_amount) <= maxAmount,
                "PRESALE: Invalid Amount"
            );
            require(
                amountRaisedPublic.add(_amount) <= hardCapPublic,
                "PRESALE: Hardcap reached"
            );
            numberOfTokens = coinToToken(_amount, tokenPricePublic);
            _fee = numberOfTokens.mul(userFee).div(100);
            if (tokenBalancePublic[msg.sender] == 0) totalUser++;
            tokenBalancePublic[msg.sender] = tokenBalancePublic[msg.sender].add(
                numberOfTokens.sub(_fee)
            );
            adminFeeCounter = adminFeeCounter.add(_fee);
            soldTokensPublic = soldTokensPublic.add(numberOfTokens);
            coinBalancePublic[msg.sender] = coinBalancePublic[msg.sender].add(
                _amount
            );
            amountRaisedPublic = amountRaisedPublic.add(_amount);
        } else if (_type == 2) {
            require(
                _amount >= minAmount &&
                    coinBalancePrivate[msg.sender].add(_amount) <= maxAmount,
                "PRESALE: Invalid Amount"
            );
            require(
                amountRaisedPrivate.add(_amount) <= hardCapPrivate,
                "PRESALE: Hardcap reached"
            );
            require(whiteListPrivate[msg.sender], "PRESALE: Not whiteListed");
            numberOfTokens = coinToToken(_amount, tokenPricePrivate);
            _fee = numberOfTokens.mul(userFee).div(100);
            if (tokenBalancePrivate[msg.sender] == 0) totalUser++;
            tokenBalancePrivate[msg.sender] = tokenBalancePrivate[msg.sender]
                .add(numberOfTokens.sub(_fee));
            adminFeeCounter = adminFeeCounter.add(_fee);
            soldTokensPrivate = soldTokensPrivate.add(numberOfTokens);
            coinBalancePrivate[msg.sender] = coinBalancePrivate[msg.sender].add(
                _amount
            );
            amountRaisedPrivate = amountRaisedPrivate.add(_amount);
        } else {
            require(
                _amount >= minAmount &&
                    coinBalanceSeed[msg.sender].add(_amount) <= maxAmount,
                "PRESALE: Invalid Amount"
            );
            require(
                amountRaisedSeed.add(_amount) <= hardCapSeed,
                "PRESALE: Hardcap reached"
            );
            require(whiteListSeed[msg.sender], "PRESALE: Not whiteListed");
            numberOfTokens = coinToToken(_amount, tokenPriceSeed);
            _fee = numberOfTokens.mul(userFee).div(100);
            if (tokenBalanceSeed[msg.sender] == 0) totalUser++;
            tokenBalanceSeed[msg.sender] = tokenBalanceSeed[msg.sender].add(
                numberOfTokens.sub(_fee)
            );
            adminFeeCounter = adminFeeCounter.add(_fee);
            soldTokensSeed = soldTokensSeed.add(numberOfTokens);
            coinBalanceSeed[msg.sender] = coinBalanceSeed[msg.sender].add(
                _amount
            );
            amountRaisedSeed = amountRaisedSeed.add(_amount);
        }

        emit TokenBought(msg.sender, numberOfTokens, _amount);
    }

    // to claim token after launch => for web3 use
    function claim() public allowed {
        require(
            block.timestamp > preSaleEndTime,
            "PRESALE: Presale time not over"
        );
        require(canClaim, "PRESALE: Wait for the owner to end preSale");
        require(
            tokenBalancePublic[msg.sender]
                .add(tokenBalancePrivate[msg.sender])
                .add(tokenBalanceSeed[msg.sender]) > 0,
            "PRESALE: No claim able balance"
        );
        require(
            claimCount[msg.sender] <= currentClaimCycle,
            "PRESALE: you have already claimed in this vesting"
        );

        // >>>> Public Sale
        if (
            amountRaisedPublic >= softCapPublic &&
            voteUp >= voteDown &&
            tokenBalancePublic[msg.sender] > 0
        ) {
            if (claimCount[msg.sender] == 0) {
                activeClaimAmountTokenPublic[msg.sender] = tokenBalancePublic[
                    msg.sender
                ].mul(vestingPercent).div(100);

                uint256 remainingCoins;
                remainingCoins = coinBalancePublic[msg.sender].sub(
                    coinBalancePublic[msg.sender].mul(projectCoinFee).div(100)
                );
                coinBalancePublic[msg.sender] = remainingCoins.sub(
                    remainingCoins.mul(liquidityPercent).div(100)
                );
                activeClaimAmountCoinPublic[msg.sender] = (
                    coinBalancePublic[msg.sender]
                ).mul(vestingPercent).div(100);

                token.transfer(
                    msg.sender,
                    activeClaimAmountTokenPublic[msg.sender]
                );
                tokenBalancePublic[msg.sender] = tokenBalancePublic[msg.sender]
                    .sub(activeClaimAmountTokenPublic[msg.sender]);
                coinBalancePublic[msg.sender] = coinBalancePublic[msg.sender]
                    .sub(activeClaimAmountCoinPublic[msg.sender]);
            } else {
                if (
                    tokenBalancePublic[msg.sender] >
                    activeClaimAmountTokenPublic[msg.sender]
                ) {
                    token.transfer(
                        msg.sender,
                        activeClaimAmountTokenPublic[msg.sender]
                    );
                    tokenBalancePublic[msg.sender] = tokenBalancePublic[
                        msg.sender
                    ].sub(activeClaimAmountTokenPublic[msg.sender]);
                    coinBalancePublic[msg.sender] = coinBalancePublic[
                        msg.sender
                    ].sub(activeClaimAmountCoinPublic[msg.sender]);
                } else {
                    token.transfer(msg.sender, tokenBalancePublic[msg.sender]);
                    tokenBalancePublic[msg.sender] = 0;
                    coinBalancePublic[msg.sender] = 0;
                }
            }

            emit TokenClaimed(
                msg.sender,
                activeClaimAmountTokenPublic[msg.sender]
            );
        } else {
            uint256 numberOfTokens = coinBalancePublic[msg.sender];

            coin.transfer(msg.sender, numberOfTokens);
            coinBalancePublic[msg.sender] = 0;

            emit CoinClaimed(msg.sender, numberOfTokens);
        }

        // >>>> Private Sale
        if (
            amountRaisedPrivate >= softCapPrivate &&
            voteUp >= voteDown &&
            whiteListPrivate[msg.sender] &&
            tokenBalancePrivate[msg.sender] > 0
        ) {
            if (claimCount[msg.sender] == 0) {
                activeClaimAmountTokenPrivate[msg.sender] = tokenBalancePrivate[
                    msg.sender
                ].mul(vestingPercent).div(100);

                uint256 remainingCoins;
                remainingCoins = coinBalancePrivate[msg.sender].sub(
                    coinBalancePrivate[msg.sender].mul(projectCoinFee).div(100)
                );
                coinBalancePrivate[msg.sender] = remainingCoins.sub(
                    remainingCoins.mul(liquidityPercent).div(100)
                );
                activeClaimAmountCoinPrivate[msg.sender] = coinBalancePrivate[
                    msg.sender
                ].mul(vestingPercent).div(100);

                token.transfer(
                    msg.sender,
                    activeClaimAmountTokenPrivate[msg.sender]
                );
                tokenBalancePrivate[msg.sender] = tokenBalancePrivate[
                    msg.sender
                ].sub(activeClaimAmountTokenPrivate[msg.sender]);
                coinBalancePrivate[msg.sender] = coinBalancePrivate[msg.sender]
                    .sub(activeClaimAmountCoinPrivate[msg.sender]);
            } else {
                if (
                    tokenBalancePrivate[msg.sender] >
                    activeClaimAmountTokenPrivate[msg.sender]
                ) {
                    token.transfer(
                        msg.sender,
                        activeClaimAmountTokenPrivate[msg.sender]
                    );
                    tokenBalancePrivate[msg.sender] = tokenBalancePrivate[
                        msg.sender
                    ].sub(activeClaimAmountTokenPrivate[msg.sender]);
                    coinBalancePrivate[msg.sender] = coinBalancePrivate[
                        msg.sender
                    ].sub(activeClaimAmountCoinPrivate[msg.sender]);
                } else {
                    token.transfer(msg.sender, tokenBalancePrivate[msg.sender]);
                    tokenBalancePrivate[msg.sender] = 0;
                    coinBalancePrivate[msg.sender] = 0;
                }
            }

            emit TokenClaimed(
                msg.sender,
                activeClaimAmountTokenPrivate[msg.sender]
            );
        } else {
            uint256 numberOfTokens = coinBalancePrivate[msg.sender];

            coin.transfer(msg.sender, numberOfTokens);
            coinBalancePrivate[msg.sender] = 0;

            emit CoinClaimed(msg.sender, numberOfTokens);
        }

        // >>>> Seed Sale
        if (
            amountRaisedSeed >= softCapSeed &&
            voteUp >= voteDown &&
            whiteListSeed[msg.sender] &&
            tokenBalanceSeed[msg.sender] > 0
        ) {
            if (claimCount[msg.sender] == 0) {
                activeClaimAmountTokenSeed[msg.sender] = tokenBalanceSeed[
                    msg.sender
                ].mul(vestingPercent).div(100);

                uint256 remainingCoins;
                remainingCoins = coinBalanceSeed[msg.sender].sub(
                    coinBalanceSeed[msg.sender].mul(projectCoinFee).div(100)
                );
                coinBalanceSeed[msg.sender] = remainingCoins.sub(
                    remainingCoins.mul(liquidityPercent).div(100)
                );
                activeClaimAmountCoinSeed[msg.sender] = coinBalanceSeed[
                    msg.sender
                ].mul(vestingPercent).div(100);

                token.transfer(
                    msg.sender,
                    activeClaimAmountTokenSeed[msg.sender]
                );
                tokenBalanceSeed[msg.sender] = tokenBalanceSeed[msg.sender].sub(
                    activeClaimAmountTokenSeed[msg.sender]
                );
                coinBalanceSeed[msg.sender] = coinBalanceSeed[msg.sender].sub(
                    activeClaimAmountCoinSeed[msg.sender]
                );
            } else {
                if (
                    tokenBalanceSeed[msg.sender] >
                    activeClaimAmountTokenSeed[msg.sender]
                ) {
                    token.transfer(
                        msg.sender,
                        activeClaimAmountTokenSeed[msg.sender]
                    );
                    tokenBalanceSeed[msg.sender] = tokenBalanceSeed[msg.sender]
                        .sub(activeClaimAmountTokenSeed[msg.sender]);
                    coinBalanceSeed[msg.sender] = coinBalanceSeed[msg.sender]
                        .sub(activeClaimAmountCoinSeed[msg.sender]);
                } else {
                    token.transfer(msg.sender, tokenBalanceSeed[msg.sender]);
                    tokenBalanceSeed[msg.sender] = 0;
                    coinBalanceSeed[msg.sender] = 0;
                }
            }

            emit TokenClaimed(
                msg.sender,
                activeClaimAmountTokenSeed[msg.sender]
            );
        } else {
            uint256 numberOfTokens = coinBalanceSeed[msg.sender];

            coin.transfer(msg.sender, numberOfTokens);
            coinBalanceSeed[msg.sender] = 0;

            emit CoinClaimed(msg.sender, numberOfTokens);
        }

        claimCount[msg.sender]++;
    }

    // withdraw the funds and initialize the liquidity pool
    function endPreSale() public onlyTokenOwner allowed {
        require(!presaleEnd, "PRESALE: Presale already ended");
        if (voteUp < voteDown) {
            token.transfer(tokenOwner, getContractTokenBalance());
            presaleEnd = true;
            return;
        }
        uint256 _adminCoinFee;
        uint256 _adminTokenFee;
        uint256 liquidityCoin;
        uint256 liquidityToken;
        uint256 refundToken;
        uint256 remainingCoin;
        // >>>> Public Sale
        if (tokenPricePublic != 0) {
            if (amountRaisedPublic >= softCapPublic) {
                if (!profitClaim) {
                    _adminCoinFee = amountRaisedPublic.mul(projectCoinFee).div(
                        100
                    );
                    _adminTokenFee = soldTokensPublic.mul(projectTokenFee).div(
                        100
                    );
                    coin.transfer(admin, _adminCoinFee);
                    token.transfer(admin, _adminTokenFee);

                    liquidityCoin = amountRaisedPublic
                        .sub(_adminCoinFee)
                        .mul(liquidityPercent)
                        .div(100);
                    liquidityToken = listingTokens(liquidityCoin);
                    token.approve(address(routerAddress), liquidityToken);
                    addLiquidity(liquidityToken, liquidityCoin);

                    refundToken = totalTokenPublic
                        .sub(soldTokensPublic)
                        .sub(liquidityToken)
                        .sub(_adminTokenFee);
                    if (refundToken > 0)
                        token.transfer(tokenOwner, refundToken);
                    remainingCoin = amountRaisedPublic.sub(_adminCoinFee).sub(
                        liquidityCoin
                    );
                    tokenOwnerProfitPublic = remainingCoin
                        .mul(vestingPercent)
                        .div(100);
                    coin.transfer(tokenOwner, tokenOwnerProfitPublic);

                    emit TokenUnSold(tokenOwner, refundToken);
                } else {
                    require(
                        // block.timestamp >= preSaleEndTime + vestingTime &&
                        claimCount[address(this)] <= currentClaimCycle,
                        "PRESALE: Wait for next claim date"
                    );
                    if (getContractcoinBalance() > tokenOwnerProfitPublic) {
                        coin.transfer(tokenOwner, tokenOwnerProfitPublic);
                    } else if (getContractcoinBalance() > 0) {
                        coin.transfer(tokenOwner, getContractcoinBalance());
                    }
                }
                claimCount[address(this)]++;
            } else {
                if (!publicRefundClaimed) {
                    token.transfer(tokenOwner, totalTokenPublic);
                    publicRefundClaimed = true;
                    emit TokenUnSold(tokenOwner, totalTokenPublic);
                }
            }
        }

        // >>>> Private Sale
        if (tokenPricePrivate != 0) {
            if (amountRaisedPrivate >= softCapPrivate) {
                if (!profitClaim) {
                    _adminCoinFee = amountRaisedPrivate.mul(projectCoinFee).div(
                            100
                        );
                    _adminTokenFee = soldTokensPrivate.mul(projectTokenFee).div(
                            100
                        );
                    coin.transfer(admin, _adminCoinFee);
                    token.transfer(admin, _adminTokenFee);
                    tokenOwnerProfitPrivate = amountRaisedPrivate
                        .mul(vestingPercent)
                        .div(100);

                    liquidityCoin = amountRaisedPrivate
                        .sub(_adminCoinFee)
                        .mul(liquidityPercent)
                        .div(100);
                    liquidityToken = listingTokens(liquidityCoin);
                    token.approve(address(routerAddress), liquidityToken);
                    addLiquidity(liquidityToken, liquidityCoin);

                    refundToken = totalTokenPrivate
                        .sub(soldTokensPrivate)
                        .sub(liquidityToken)
                        .sub(_adminTokenFee);
                    if (refundToken > 0)
                        token.transfer(tokenOwner, refundToken);
                    remainingCoin = amountRaisedPrivate.sub(_adminCoinFee).sub(
                        liquidityCoin
                    );
                    tokenOwnerProfitPrivate = remainingCoin
                        .mul(vestingPercent)
                        .div(100);
                    coin.transfer(tokenOwner, tokenOwnerProfitPrivate);

                    emit TokenUnSold(tokenOwner, refundToken);
                } else {
                    require(
                        // block.timestamp >= preSaleEndTime + vestingTime &&
                        claimCount[msg.sender] <= currentClaimCycle,
                        "PRESALE: Wait for next claim date"
                    );
                    if (getContractcoinBalance() > tokenOwnerProfitPrivate) {
                        coin.transfer(tokenOwner, tokenOwnerProfitPrivate);
                    } else if (getContractcoinBalance() > 0) {
                        coin.transfer(tokenOwner, getContractcoinBalance());
                    }
                }
            } else {
                if (!privateRefundClaimed) {
                    token.transfer(tokenOwner, totalTokenPrivate);
                    privateRefundClaimed = true;

                    emit TokenUnSold(tokenOwner, totalTokenPrivate);
                }
            }
        }

        // >>>> Seed Sale
        if (tokenPriceSeed != 0) {
            if (amountRaisedSeed >= softCapSeed) {
                if (!profitClaim) {
                    _adminCoinFee = amountRaisedSeed.mul(projectCoinFee).div(
                        100
                    );
                    _adminTokenFee = soldTokensSeed.mul(projectTokenFee).div(
                        100
                    );
                    coin.transfer(admin, _adminCoinFee);
                    token.transfer(admin, _adminTokenFee);
                    tokenOwnerProfitSeed = amountRaisedSeed
                        .mul(vestingPercent)
                        .div(100);

                    liquidityCoin = amountRaisedSeed
                        .sub(_adminCoinFee)
                        .mul(liquidityPercent)
                        .div(100);
                    liquidityToken = listingTokens(liquidityCoin);
                    token.approve(address(routerAddress), liquidityToken);
                    coin.approve(address(routerAddress), liquidityCoin);
                    addLiquidity(liquidityToken, liquidityCoin);

                    refundToken = totalTokenSeed
                        .sub(soldTokensSeed)
                        .sub(liquidityToken)
                        .sub(soldTokensSeed.mul(_adminTokenFee).div(100));
                    if (refundToken > 0)
                        token.transfer(tokenOwner, refundToken);
                    remainingCoin = amountRaisedSeed.sub(_adminCoinFee).sub(
                        liquidityCoin
                    );
                    tokenOwnerProfitSeed = remainingCoin
                        .mul(vestingPercent)
                        .div(100);
                    coin.transfer(tokenOwner, tokenOwnerProfitSeed);

                    emit TokenUnSold(tokenOwner, refundToken);
                } else {
                    require(
                        // block.timestamp >= preSaleEndTime + vestingTime &&
                        claimCount[msg.sender] <= currentClaimCycle,
                        "PRESALE: Wait for next claim date"
                    );
                    if (getContractcoinBalance() > tokenOwnerProfitSeed) {
                        coin.transfer(tokenOwner, tokenOwnerProfitSeed);
                    } else if (getContractcoinBalance() > 0) {
                        coin.transfer(tokenOwner, getContractcoinBalance());
                    }
                }
            } else {
                if (!seedRefundClaimed) {
                    token.transfer(tokenOwner, totalTokenSeed);
                    seedRefundClaimed = true;
                    emit TokenUnSold(tokenOwner, totalTokenSeed);
                }
            }
        }
        if (!profitClaim) {
            profitClaim = true;
            preSaleEndTime = block.timestamp;
            canClaim = true;
            if (adminFeeCounter > 0) token.transfer(admin, adminFeeCounter);
            adminFeeCounter = 0;
        }
    }

    function vote(bool _vote) public {
        require(
            token.balanceOf(msg.sender) > 0,
            "VOTING: Voter must be a holder"
        );
        require(
            !usersVoting[msg.sender][currentVotingCycle].voteCasted,
            "VOTING: Already cast a vote"
        );
        require(votingStatus, "VOTING: Not Allowed");
        require(
            block.timestamp >= votingStartTime &&
                block.timestamp < votingEndTime,
            "VOTING: Wrong Timing"
        );

        usersVoting[msg.sender][currentVotingCycle].vote = _vote;
        usersVoting[msg.sender][currentVotingCycle].voteCasted = true;

        if (_vote) {
            voteUp = voteUp.add(1);
        } else {
            voteDown = voteDown.add(1);
        }
    }

    function addLiquidity(uint256 tokenAmount, uint256 coinAmount) internal {
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(routerAddress);

        // add the liquidity
        pancakeRouter.addLiquidity(
            address(coin),
            address(token),
            coinAmount,
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            tokenOwner,
            block.timestamp + 300
        );
    }

    function startVoting(uint256 _endTime) external onlyAdmin {
        require(!votingStatus, "VOTING: Already started");
        require(
            block.timestamp > preSaleEndTime.add(vestingTime),
            "VOTING: Presale not end"
        );
        votingStatus = true;
        voteUp = 0;
        voteDown = 0;
        votingStartTime = block.timestamp;
        votingEndTime = block.timestamp.add(_endTime);
        currentVotingCycle++;
    }

    function endVoting() external onlyAdmin {
        require(votingStatus, "VOTING: Already ended");
        votingStatus = false;
        vestingTime = vestingTime.add(vestingTimeStep);
        currentClaimCycle++;
    }

    function setWhiteListPrivate(address[] memory _users)
        external
        onlyTokenOwner
    {
        for (uint256 i = 0; i < _users.length; i++) {
            whiteListPrivate[_users[i]] = true;
        }
    }

    function setWhiteListSeed(address[] memory _users) external onlyTokenOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            whiteListSeed[_users[i]] = true;
        }
    }

    // to check number of token for buying
    function coinToToken(uint256 _amount, uint256 _tokenPrice)
        public
        view
        returns (uint256)
    {
        uint256 numberOfTokens = _amount.mul(_tokenPrice);
        return
            numberOfTokens.mul(10**(token.decimals())).div(
                10**(coin.decimals())
            );
    }

    // to calculate number of tokens for listing price
    function listingTokens(uint256 _amount) public view returns (uint256) {
        uint256 numberOfTokens = _amount.mul(listingPrice);
        return
            numberOfTokens.mul(10**(token.decimals())).div(
                10**(coin.decimals())
            );
    }

    // to Stop preSale in case of scam
    function setAllow(bool _enable) external onlyAdmin {
        allow = _enable;
    }

    function getContractcoinBalance() public view returns (uint256) {
        return coin.balanceOf(address(this));
    }

    function getContractTokenBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function getCurrentTime() public view returns (uint256) {
        return block.timestamp;
    }

    // get user voting data
    function getUserVotingData(address _user, uint256 _votingIndex)
        public
        view
        returns (bool _vote, bool _voteCasted)
    {
        return (
            usersVoting[_user][_votingIndex].vote,
            usersVoting[_user][_votingIndex].voteCasted
        );
    }

    function removeStuckBnb() external onlyAdmin {
        payable(admin).transfer(address(this).balance);
    }

    function removeStuckToken(address _token, uint256 _amount) external onlyAdmin {
        IERC20(_token).transfer(admin, _amount);
    }
}

pragma solidity ^0.8.4;

//  SPDX-License-Identifier: MIT

library SafeMath {
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.8.9;
// SPDX-License-Identifier: MIT

import './IERC20.sol';
import '../Libraries/SafeMath.sol';
import './IPancakeRouter02.sol';

interface IPreSale{

    function admin() external view returns(address);
    function tokenOwner() external view returns(address);
    function deployer() external view returns(address);
    function coin() external view returns(address);
    function token() external view returns(address);

    function tokenPrice() external view returns(uint256);
    function preSaleTime() external view returns(uint256);
    function claimTime() external view returns(uint256);
    function minAmount() external view returns(uint256);
    function maxAmount() external view returns(uint256);
    function softCap() external view returns(uint256);
    function hardCap() external view returns(uint256);
    function listingPrice() external view returns(uint256);
    function liquidityPercent() external view returns(uint256);

    function allow() external view returns(bool);

    function initialize(
        address _admin,
        address _tokenOwner,
        IERC20 _coin,
        IERC20 _token,
        address _routerAddress,
        uint256 _userFee,
        uint256 _projectCoinFee,
        uint256 _projectTokenFee,
        uint256[] memory _data
    ) external ;

    
}

pragma solidity ^0.8.4;

// SPDX-License-Identifier:MIT

interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity ^0.8.4;

// SPDX-License-Identifier: MIT

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external;
    function transfer(address to, uint value) external;
    function transferFrom(address from, address to, uint value) external;
}