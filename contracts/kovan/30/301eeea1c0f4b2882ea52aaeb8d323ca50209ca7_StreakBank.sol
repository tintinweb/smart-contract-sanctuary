// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "./Ownable.sol";
import "./Pausable.sol";
import "./IERC20.sol";
import "./ILendingPoolAddressesProvider.sol";
import "./ILendingPool.sol";
import "./AToken.sol";

contract StreakBank is Ownable, Pausable {
    /// @notice Address of the token used for depositing into the game by players (DAI)
    IERC20 public immutable daiToken;
    /// @notice Address of the interest bearing token received when funds are transferred to the external pool
    AToken public immutable adaiToken;
    /// @notice Which Aave instance we use to swap DAI to interest bearing aDAI
    ILendingPoolAddressesProvider public immutable lendingPoolAddressProvider;
    /// @notice Lending pool address
    ILendingPool public lendingPool;

    struct Player {
        bool withdrawn;
        address addr;
        uint256 segmentJoined;
        uint256 mostRecentSegmentPaid;
        uint256 amountPaid;
        uint256 amountEachSegment;
    }

    /// @notice Stores info about the players in the game
    mapping(address => Player) public players;

    /// @notice Controls the amount of active players in the game (ignores players that early withdraw)
    uint256 public activePlayersCount = 0;

    /// @notice total principal amount
    uint256 public totalGamePrincipal;

    /// @notice When the game started (deployed timestamp)
    uint256 public immutable firstSegmentStart;

    /// @notice The time duration (in seconds) of each segment
    uint256 public immutable segmentLength;

    /// @notice Number of segments players have to stay in game for the interest (input 3 if players can withdraw after 4th deposit)
    uint256 public immutable minSegmentForReward;

    event JoinedGame(address indexed player, uint256 amount);
    event Deposit(
        address indexed player,
        uint256 indexed segment,
        uint256 amount
    );
    event Withdrawal(
        address indexed player,
        uint256 amount,
        uint256 playerReward
    );

    /**
        Creates a new instance of StreakBank game
        @param _inboundCurrency Smart contract address of inbound currency used for the game.
        @param _lendingPoolAddressProvider Smart contract address of the lending pool adddress provider.
        @param _segmentLength Lenght of each segment, in seconds (i.e., 180 (sec) => 3 minutes).
        @param _minSegmentForReward Number of segments players have to stay in game for the interest (input 3 if players can withdraw after 4th deposit).
        @param _dataProvider id for getting the data provider contract address 0x1 to be passed.
     */
    constructor(
        IERC20 _inboundCurrency,
        ILendingPoolAddressesProvider _lendingPoolAddressProvider,
        uint256 _segmentLength,
        uint256 _minSegmentForReward,
        address _dataProvider
    ) {
        require(
            address(_inboundCurrency) != address(0),
            "invalid _inboundCurrency address"
        );
        require(
            address(_lendingPoolAddressProvider) != address(0),
            "invalid _lendingPoolAddressProvider address"
        );
        require(_segmentLength > 0, "_segmentLength must be greater than zero");
        require(
            _minSegmentForReward > 0,
            "_minSegmentForReward must be greater than zero"
        );
        require(_dataProvider != address(0), "invalid _dataProvider address");
        // Initializes default variables
        firstSegmentStart = block.timestamp; //gets current time
        segmentLength = _segmentLength;
        minSegmentForReward = _minSegmentForReward;
        daiToken = _inboundCurrency;
        lendingPoolAddressProvider = _lendingPoolAddressProvider;
        AaveProtocolDataProvider dataProvider = AaveProtocolDataProvider(
            _dataProvider
        );
        // lending pool needs to be approved in v2 since it is the core contract in v2 and not lending pool core
        lendingPool = ILendingPool(
            _lendingPoolAddressProvider.getLendingPool()
        );
        // atoken address in v2 is fetched from data provider contract
        (address adaiTokenAddress, , ) = dataProvider.getReserveTokensAddresses(
            address(_inboundCurrency)
        );
        adaiToken = AToken(adaiTokenAddress);
    }

    /// @notice pauses the game. This function can be called only by the contract's admin.
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /// @notice unpauses the game. This function can be called only by the contract's admin.
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    /// @notice Calculates the current segment of the game.
    /// @return current game segment
    function getCurrentSegment() public view returns (uint256) {
        return (block.timestamp - firstSegmentStart) / segmentLength;
    }

    /**
        Allows a player to join the game - external & can override
        @param segmentPayment Amount of tokens each player decides to contribute per segment (i.e. 10*10**18 equals to 10 DAI - note that DAI uses 18 decimal places).
     */
    function joinGame(uint256 segmentPayment) external virtual whenNotPaused {
        _joinGame(segmentPayment);
    }

    /**
        Allows a player to join the game - internal
        @param segmentPayment Amount of tokens each player decides to contribute per segment (i.e. 10*10**18 equals to 10 DAI - note that DAI uses 18 decimal places).
     */
    function _joinGame(uint256 segmentPayment) internal {
        require(
            players[msg.sender].addr != msg.sender ||
                players[msg.sender].withdrawn,
            "Cannot join the game while already in it"
        );

        activePlayersCount++;
        uint256 currentSegment = getCurrentSegment();

        Player memory newPlayer = Player({
            withdrawn: false,
            addr: msg.sender,
            segmentJoined: currentSegment,
            mostRecentSegmentPaid: 0,
            amountPaid: 0,
            amountEachSegment: segmentPayment
        });
        players[msg.sender] = newPlayer;
        emit JoinedGame(msg.sender, segmentPayment);
        _transferDaiToContract(currentSegment, segmentPayment);
    }

    /**
        Manages the transfer of funds from the player to the contract, recording
        the required accounting operations to control the user's position in the pool.
        @param currentSegment Current Segment number
        @param segmentPayment Amount of tokens each player decides to contribute per segment (i.e. 10*10**18 equals to 10 DAI - note that DAI uses 18 decimal places).
     */
    function _transferDaiToContract(
        uint256 currentSegment,
        uint256 segmentPayment
    ) internal {
        require(
            daiToken.allowance(msg.sender, address(this)) >= segmentPayment,
            "You need to have allowance to do transfer DAI on the smart contract"
        );

        require(
            daiToken.transferFrom(msg.sender, address(this), segmentPayment),
            "Transfer failed"
        );

        players[msg.sender].mostRecentSegmentPaid = currentSegment;
        players[msg.sender].amountPaid += segmentPayment;
        totalGamePrincipal += segmentPayment;

        // Allows the lending pool to convert DAI deposited on this contract to aDAI on lending pool
        uint256 contractBalance = daiToken.balanceOf(address(this));
        require(
            daiToken.approve(address(lendingPool), contractBalance),
            "Fail to approve allowance to lending pool"
        );

        lendingPool.deposit(
            address(daiToken),
            contractBalance,
            address(this),
            0
        );
    }

    /// @notice Allows players to make deposits for the game segments, after joining the game.
    function makeDeposit() external whenNotPaused {
        Player storage player = players[msg.sender];
        // only registered players can deposit
        require(player.addr == msg.sender, "Sender is not a player");

        uint256 currentSegment = getCurrentSegment();

        //check if current segment is currently unpaid
        require(
            player.mostRecentSegmentPaid != currentSegment,
            "Player already paid current segment"
        );

        // check if player has made payments up to the previous segment
        require(
            player.mostRecentSegmentPaid == (currentSegment - 1),
            "Player didn't pay the previous segment - game over!"
        );

        _transferDaiToContract(currentSegment, player.amountEachSegment);
        emit Deposit(msg.sender, currentSegment, player.amountEachSegment);
    }

    /// @notice Allows a player to withdraw funds
    function withdraw() external whenNotPaused {
        Player storage player = players[msg.sender];
        require(player.amountPaid > 0, "Player does not exist");
        require(!player.withdrawn, "Player has already withdrawn");
        player.withdrawn = true;
        activePlayersCount--;

        uint256 withdrawAmount = player.amountPaid;
        uint256 currentSegment = getCurrentSegment();
        uint256 playerReward = 0;

        if (
            player.mostRecentSegmentPaid >= (currentSegment - 1) &&
            (player.mostRecentSegmentPaid - player.segmentJoined) >
            minSegmentForReward
        ) {
            // Player is eligible for interest
            playerReward =
                ((adaiToken.balanceOf(address(this)) - totalGamePrincipal) *
                    player.amountPaid) /
                totalGamePrincipal;
            withdrawAmount += playerReward;
        }

        lendingPool.withdraw(address(daiToken), withdrawAmount, address(this));
        require(
            IERC20(daiToken).transfer(msg.sender, withdrawAmount),
            "Fail to transfer ERC20 tokens on early withdraw"
        );

        emit Withdrawal(msg.sender, withdrawAmount, playerReward);
    }
}