/**
 *Submitted for verification at polygonscan.com on 2021-10-10
*/

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.9;

/// @notice Minimal ERC-20 token interface with metaTx.
interface IERC20MinimalMeta { 
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    /// @dev metaTx:
    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) external payable returns (bytes memory);
}

/// @notice SushiToken Battle Royale on Polygon.
contract SquishiGame {
    event Join(address indexed player);
    event Hit(address indexed hitter, address indexed victim);
    event Heal(address indexed healer, address indexed friend);
    event Death(address indexed player);
    event ClaimWinnings(address indexed player, uint256 indexed winnings);

    /// @dev SushiToken:
    IERC20MinimalMeta public constant sushi = IERC20MinimalMeta(0x0b3F868E0BE5597D5DB7fEB59E1CADBb0fdDa50a);
    
    /// @dev Game variables:
    uint256 public immutable gameEnds = block.timestamp + 9 days;
    uint256 public players;
    uint256 internal finalPot;
    uint256 public potClaimed;
    
    /// @dev For ERC20-like mint/burn:
    string public constant name = "Squishi Game";
    string public constant symbol = "SQUISHI";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    mapping(address => uint256) public balanceOf; /// @dev ERC-20-like.
    
    mapping(address => bool) public claimers;
    mapping(address => bool) public rip; /// @dev Confirms player death.
    mapping(address => uint256) public lastActionTimestamp;
    
    uint256 internal unlocked = 1;
    modifier lock() {
        require(unlocked == 1, "LOCKED");
        unlocked = 2;
        _;
        unlocked = 1;
    }
    
    modifier rested() {
        require(block.timestamp - lastActionTimestamp[msg.sender] > 1 hours, "RESTING");
        _;
    }

    // **** JOIN ****
    
    /// @notice Deposit sushi and join game.
    function join() public lock {
        require(block.timestamp < gameEnds, "GAME_OVER");
        require(block.timestamp < gameEnds - 3 days, "TOO_LATE"); /// @dev Most action probably in last 3 days of game anyways.
        require(!rip[msg.sender], "ALREADY_DEAD");
        require(!isAlive(msg.sender), "ALREADY_PLAYING");
        require(
            /// @dev Take 3 sushi to give life to new player.
            sushi.transferFrom(msg.sender, address(this), 3 ether)
            &&
            /// @dev Burn 0.1 sushi to squishi gods.
            sushi.transfer(address(0xdead), 1 ether / 10)
            , "SUSHI_TXS_FAILED"
        );
        
        _mint(msg.sender, 9 ether);

        players++;
        
        emit Join(msg.sender);
    }
    
    /// @notice Deposit sushi and join game via metaTx.
    function joinWithMetaTx(
        bytes calldata functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public {
        IERC20MinimalMeta(sushi).executeMetaTransaction(
            msg.sender,
            functionSignature,
            sigR,
            sigS,
            sigV
        );
        join();
    }

    // **** PLAY ****
    
    function pot() public view returns (uint256 value) {
        value = sushi.balanceOf(address(this));
    }
    
    /// @notice Check if player is still alive.
    function isAlive(address player) public view returns (bool alive) {
        alive = balanceOf[player] > 0;
    }
    
    /// @notice Attack another player.
    function hit(address victim) public lock rested {
        require(block.timestamp < gameEnds, "GAME_OVER");
        require(isAlive(msg.sender), "YOU_ARE_DEAD");
        require(isAlive(victim), "THEY_ARE_DEAD");
        
        _burn(victim, 1 ether);

        lastActionTimestamp[msg.sender] = block.timestamp;
        
        emit Hit(msg.sender, victim);
        
        if (balanceOf[victim] == 0) {
            players--;
            rip[victim] = true;
            emit Death(victim);
        }
    }
    
    /// @notice Heal another player.
    function heal(address friend) public lock rested {
        require(block.timestamp < gameEnds, "GAME_OVER");
        require(isAlive(msg.sender), "YOU_ARE_DEAD");
        require(isAlive(friend), "THEY_ARE_DEAD");
        require(balanceOf[friend] < 9 ether, "ALREADY_HEALED");
        
        _mint(friend, 1 ether);
        
        lastActionTimestamp[msg.sender] = block.timestamp;
        
        emit Heal(msg.sender, friend);
    }
    
    // **** WIN ****
    
    /// @notice Remaining players can claim fair share of sushi pot.
    function claimWinnings() public lock {
        require(block.timestamp >= gameEnds, "GAME_NOT_OVER");
        require(isAlive(msg.sender), "YOU_ARE_DEAD");
        require(!claimers[msg.sender], "ALREADY_CLAIMED");
        
        if (potClaimed == 0) {
            finalPot = pot();
        }
        
        uint256 claim = finalPot / players;
        
        claimers[msg.sender] = true;
        
        sushi.transfer(msg.sender, claim);
        
        potClaimed += claim;

        emit ClaimWinnings(msg.sender, claim);
    }
    
    /*/////////////////////////////////////////////////////////////*/
    
    function _mint(address to, uint256 value) internal {
        totalSupply += value;

        balanceOf[to] += value;

        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        balanceOf[from] -= value;

        totalSupply -= value;

        emit Transfer(from, address(0), value);
    }
}