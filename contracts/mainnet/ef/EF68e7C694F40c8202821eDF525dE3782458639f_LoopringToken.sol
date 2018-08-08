/*

  Copyright 2017 Loopring Foundation.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/
pragma solidity ^0.4.11;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function transfer(address to, uint value);
  event Transfer(address indexed from, address indexed to, uint value);
}

/**
 * Math operations with safety checks
 */
library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances. 
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint;

  mapping(address => uint) balances;

  /**
   * @dev Fix for the ERC20 short address attack.
   */
  modifier onlyPayloadSize(uint size) {
     if(msg.data.length < size + 4) {
       throw;
     }
     _;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of. 
  * @return An uint representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }

}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint);
  function transferFrom(address from, address to, uint value);
  function approve(address spender, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implemantation of the basic standart token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is BasicToken, ERC20 {

  mapping (address => mapping (address => uint)) allowed;

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // if (_value > _allowance) throw;

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on beahlf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint _value) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

  /**
   * @dev Function to check the amount of tokens than an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}

/// @title Loopring Protocol Token.
/// For more information about this token sale, please visit https://loopring.org
/// @author Kongliang Zhong - <<span class="__cf_email__" data-cfemail="412a2e2f262d28202f26012d2e2e3133282f266f2e3326">[email&#160;protected]</span>>, Daniel Wang - <<span class="__cf_email__" data-cfemail="7a1e1b14131f163a1615150a0813141d5415081d">[email&#160;protected]</span>>.
contract LoopringToken is StandardToken {
    string public constant NAME = "LoopringCoin";
    string public constant SYMBOL = "LRC";
    uint public constant DECIMALS = 18;

    /// During token sale, we use one consistent price: 5000 LRC/ETH.
    /// We split the entire token sale period into 10 phases, each
    /// phase has a different bonus setting as specified in `bonusPercentages`.
    /// The real price for phase i is `(1 + bonusPercentages[i]/100.0) * BASE_RATE`.
    /// The first phase or early-bird phase has a much higher bonus.
    uint8[10] public bonusPercentages = [
        20,
        16,
        14,
        12,
        10,
        8,
        6,
        4,
        2,
        0
    ];

    uint public constant NUM_OF_PHASE = 10;
  
    /// Each phase contains exactly 15250 Ethereum blocks, which is roughly 3 days,
    /// which makes this 10-phase sale period roughly 30 days.
    /// See https://www.ethereum.org/crowdsale#scheduling-a-call
    uint16 public constant BLOCKS_PER_PHASE = 15250;

    /// This is where we hold ETH during this token sale. We will not transfer any Ether
    /// out of this address before we invocate the `close` function to finalize the sale. 
    /// This promise is not guanranteed by smart contract by can be verified with public
    /// Ethereum transactions data available on several blockchain browsers.
    /// This is the only address from which `start` and `close` can be invocated.
    ///
    /// Note: this will be initialized during the contract deployment.
    address public target;

    /// `firstblock` specifies from which block our token sale starts.
    /// This can only be modified once by the owner of `target` address.
    uint public firstblock = 0;

    /// Indicates whether unsold token have been issued. This part of LRC token
    /// is managed by the project team and is issued directly to `target`.
    bool public unsoldTokenIssued = false;

    /// Minimum amount of funds to be raised for the sale to succeed. 
    uint256 public constant GOAL = 50000 ether;

    /// Maximum amount of fund to be raised, the sale ends on reaching this amount.
    uint256 public constant HARD_CAP = 120000 ether;

    /// Maximum unsold ratio, this is hit when the mininum level of amount of fund is raised.
    uint public constant MAX_UNSOLD_RATIO = 675; // 67.5%

    /// Base exchange rate is set to 1 ETH = 5000 LRC.
    uint256 public constant BASE_RATE = 5000;

    /// A simple stat for emitting events.
    uint public totalEthReceived = 0;

    /// Issue event index starting from 0.
    uint public issueIndex = 0;

    /* 
     * EVENTS
     */

    /// Emitted only once after token sale starts.
    event SaleStarted();

    /// Emitted only once after token sale ended (all token issued).
    event SaleEnded();

    /// Emitted when a function is invocated by unauthorized addresses.
    event InvalidCaller(address caller);

    /// Emitted when a function is invocated without the specified preconditions.
    /// This event will not come alone with an exception.
    event InvalidState(bytes msg);

    /// Emitted for each sucuessful token purchase.
    event Issue(uint issueIndex, address addr, uint ethAmount, uint tokenAmount);

    /// Emitted if the token sale succeeded.
    event SaleSucceeded();

    /// Emitted if the token sale failed.
    /// When token sale failed, all Ether will be return to the original purchasing
    /// address with a minor deduction of transaction fee（gas)
    event SaleFailed();

    /*
     * MODIFIERS
     */

    modifier onlyOwner {
        if (target == msg.sender) {
            _;
        } else {
            InvalidCaller(msg.sender);
            throw;
        }
    }

    modifier beforeStart {
        if (!saleStarted()) {
            _;
        } else {
            InvalidState("Sale has not started yet");
            throw;
        }
    }

    modifier inProgress {
        if (saleStarted() && !saleEnded()) {
            _;
        } else {
            InvalidState("Sale is not in progress");
            throw;
        }
    }

    modifier afterEnd {
        if (saleEnded()) {
            _;
        } else {
            InvalidState("Sale is not ended yet");
            throw;
        }
    }

    /**
     * CONSTRUCTOR 
     * 
     * @dev Initialize the Loopring Token
     * @param _target The escrow account address, all ethers will
     * be sent to this address.
     * This address will be : 0x00073F7155459C9205010Cb3453a0f392a0C3210
     */
    function LoopringToken(address _target) {
        target = _target;
    }

    /*
     * PUBLIC FUNCTIONS
     */

    /// @dev Start the token sale.
    /// @param _firstblock The block from which the sale will start.
    function start(uint _firstblock) public onlyOwner beforeStart {
        if (_firstblock <= block.number) {
            // Must specify a block in the future.
            throw;
        }

        firstblock = _firstblock;
        SaleStarted();
    }

    /// @dev Triggers unsold tokens to be issued to `target` address.
    function close() public onlyOwner afterEnd {
        if (totalEthReceived < GOAL) {
            SaleFailed();
        } else {
            issueUnsoldToken();
            SaleSucceeded();
        }
    }

    /// @dev Returns the current price.
    function price() public constant returns (uint tokens) {
        return computeTokenAmount(1 ether);
    }

    /// @dev This default function allows token to be purchased by directly
    /// sending ether to this smart contract.
    function () payable {
        issueToken(msg.sender);
    }

    /// @dev Issue token based on Ether received.
    /// @param recipient Address that newly issued token will be sent to.
    function issueToken(address recipient) payable inProgress {
        // We only accept minimum purchase of 0.01 ETH.
        assert(msg.value >= 0.01 ether);

        uint tokens = computeTokenAmount(msg.value);
        totalEthReceived = totalEthReceived.add(msg.value);
        totalSupply = totalSupply.add(tokens);
        balances[recipient] = balances[recipient].add(tokens);

        Issue(
            issueIndex++,
            recipient,
            msg.value,
            tokens
        );

        if (!target.send(msg.value)) {
            throw;
        }
    }

    /*
     * INTERNAL FUNCTIONS
     */
  
    /// @dev Compute the amount of LRC token that can be purchased.
    /// @param ethAmount Amount of Ether to purchase LRC.
    /// @return Amount of LRC token to purchase
    function computeTokenAmount(uint ethAmount) internal constant returns (uint tokens) {
        uint phase = (block.number - firstblock).div(BLOCKS_PER_PHASE);

        // A safe check
        if (phase >= bonusPercentages.length) {
            phase = bonusPercentages.length - 1;
        }

        uint tokenBase = ethAmount.mul(BASE_RATE);
        uint tokenBonus = tokenBase.mul(bonusPercentages[phase]).div(100);

        tokens = tokenBase.add(tokenBonus);
    }

    /// @dev Issue unsold token to `target` address.
    /// The math is as follows:
    ///   +-------------------------------------------------------------+
    ///   |       Total Ethers Received        |                        |
    ///   +------------------------------------+  Unsold Token Portion  |
    ///   |   Lower Bound   |   Upper Bound    |                        |
    ///   +-------------------------------------------------------------+
    ///   |      50,000     |     60,000       |         67.5%          |
    ///   +-------------------------------------------------------------+
    ///   |      60,000     |     70,000       |         65.0%          |
    ///   +-------------------------------------------------------------+
    ///   |      70,000     |     80,000       |         62.5%          |
    ///   +-------------------------------------------------------------+
    ///   |      80,000     |     90,000       |         60.0%          |
    ///   +-------------------------------------------------------------+
    ///   |      90,000     |    100,000       |         57.5%          |
    ///   +-------------------------------------------------------------+
    ///   |     100,000     |    110,000       |         55.0%          |
    ///   +-------------------------------------------------------------+
    ///   |     110,000     |    120,000       |         52.5%          |
    ///   +-------------------------------------------------------------+
    ///   |     120,000     |                  |         50.0%          |
    ///   +-------------------------------------------------------------+
    function issueUnsoldToken() internal {
        if (unsoldTokenIssued) {
            InvalidState("Unsold token has been issued already");
        } else {
            // Add another safe guard 
            require(totalEthReceived >= GOAL);

            uint level = totalEthReceived.sub(GOAL).div(10000 ether);
            if (level > 7) {
                level = 7;
            }

            uint unsoldRatioInThousand = MAX_UNSOLD_RATIO - 25 * level;


            // Calculate the `unsoldToken` to be issued, the amount of `unsoldToken`
            // is based on the issued amount, that is the `totalSupply`, during 
            // the sale:
            //                   totalSupply
            //   unsoldToken = --------------- * r
            //                      1 - r
            uint unsoldToken = totalSupply.div(1000 - unsoldRatioInThousand).mul(unsoldRatioInThousand);

            // Adjust `totalSupply`.
            totalSupply = totalSupply.add(unsoldToken);
            // Issue `unsoldToken` to the target account.
            balances[target] = balances[target].add(unsoldToken);

            Issue(
                issueIndex++,
                target,
                0,
                unsoldToken
            );
            
            unsoldTokenIssued = true;
        }
    }

    /// @return true if sale has started, false otherwise.
    function saleStarted() constant returns (bool) {
        return (firstblock > 0 && block.number >= firstblock);
    }

    /// @return true if sale has ended, false otherwise.
    function saleEnded() constant returns (bool) {
        return firstblock > 0 && (saleDue() || hardCapReached());
    }

    /// @return true if sale is due when the last phase is finished.
    function saleDue() constant returns (bool) {
        return block.number >= firstblock + BLOCKS_PER_PHASE * NUM_OF_PHASE;
    }

    /// @return true if the hard cap is reached.
    function hardCapReached() constant returns (bool) {
        return totalEthReceived >= HARD_CAP;
    }
}