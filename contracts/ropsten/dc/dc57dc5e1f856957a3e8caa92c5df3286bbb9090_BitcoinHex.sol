pragma solidity ^0.4.23;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}



/*

  UTXO redeemable token.

  This is a token extension to allow porting a Bitcoin or Bitcoin-fork sourced UTXO set to an ERC20 token through redemption of individual UTXOs in the token contract.
    
  Owners of UTXOs in a chosen final set (where "owner" is simply anyone who could have spent the UTXO) are allowed to redeem (mint) a number of tokens proportional to the satoshi amount of the UTXO.

  Notes

    - This method *does not* provision for special Bitcoin scripts (e.g. multisig addresses).
    - Pending transactions are public, so the UTXO redemption transaction must work *only* for an Ethereum address belonging to the same person who owns the UTXO.
      This is enforced by requiring that the redeeemer sign their Ethereum address with their Bitcoin (original-chain) private key.
    - We cannot simply store the UTXO set, as that would be far too expensive. Instead we compute a Merkle tree for the entire UTXO set at the chain state which is to be ported,
      store only the root of that Merkle tree, and require UTXO claimants prove that the UTXO they wish to claim is present in the tree.

*/












/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}



/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}






/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}



/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}




/*
 * @title MerkleProof
 * @dev Merkle proof verification
 * @note Based on https://github.com/ameensol/merkle-tree-solidity/blob/master/src/MerkleProof.sol
 */
library MerkleProof {
  /*
   * @dev Verifies a Merkle proof proving the existence of a leaf in a Merkle tree. Assumes that each pair of leaves
   * and each pair of pre-images is sorted.
   * @param _proof Merkle proof containing sibling hashes on the branch from the leaf to the root of the Merkle tree
   * @param _root Merkle root
   * @param _leaf Leaf of Merkle tree
   */
  function verifyProof(
    bytes32[] _proof,
    bytes32 _root,
    bytes32 _leaf
  )
    internal
    pure
    returns (bool)
  {
    bytes32 computedHash = _leaf;

    for (uint256 i = 0; i < _proof.length; i++) {
      bytes32 proofElement = _proof[i];

      if (computedHash < proofElement) {
        // Hash(current computed hash + current element of the proof)
        computedHash = keccak256(computedHash, proofElement);
      } else {
        // Hash(current element of the proof + current computed hash)
        computedHash = keccak256(proofElement, computedHash);
      }
    }

    // Check if the computed hash (root) is equal to the provided root
    return computedHash == _root;
  }
}


/* solium-disable security/no-block-members */


/**
* Based on https://github.com/ProjectWyvern/wyvern-ethereum
*/
contract UTXORedeemableToken is StandardToken {

    /* Origin Address */
    address public origin;

    /* Store time of launch for contract */
    uint256 public launchTime;

    /* Store last updated week */
    uint256 public lastUpdatedWeek = 0;

    struct WeekDataStruct {
        uint256 unclaimedCoins;
    }

    /* Weekly update data */
    mapping(uint256 => WeekDataStruct) weekData;

    /* Root hash of the UTXO Merkle tree, must be initialized by token constructor. */
    bytes32 public rootUTXOMerkleTreeHash;

    /* Redeemed UTXOs. */
    mapping(bytes32 => bool) redeemedUTXOs;

    /* Total tokens redeemed so far. */
    uint256 public totalRedeemed;

    /* Maximum redeemable tokens, must be initialized by token constructor. */
    uint256 public maximumRedeemable;

    /* Claim, stake, and minting events need to happen atleast once every week for this function to
       run automatically, otherwise function can be manually called for that week */
    function storeWeekUnclaimed() public {
        uint256 weeksSinceLaunch = block.timestamp.sub(launchTime).div(7 days);
        if (weeksSinceLaunch < 51 && weeksSinceLaunch > lastUpdatedWeek) {
            uint256 unclaimedCoins = maximumRedeemable.sub(totalRedeemed);
            weekData[weeksSinceLaunch] = WeekDataStruct(unclaimedCoins);
            lastUpdatedWeek = weeksSinceLaunch;
        }
    }

    /**
     * @dev Extract a bytes32 subarray from an arbitrary length bytes array.
     * @param data Bytes array from which to extract the subarray
     * @param pos Starting position from which to copy
     * @return Extracted length 32 byte array
     */
    function extract(bytes data, uint256 pos) private pure returns (bytes32 result) { 
        for (uint256 i = 0; i < 32; i++) {
            result ^= (bytes32(0xff00000000000000000000000000000000000000000000000000000000000000) & data[i + pos]) >> (i * 8);
        }
        return result;
    }
    
    /**
     * @dev Validate that a provided ECSDA signature was signed by the specified address
     * @param hash Hash of signed data
     * @param v v parameter of ECDSA signature
     * @param r r parameter of ECDSA signature
     * @param s s parameter of ECDSA signature
     * @param expected Address claiming to have created this signature
     * @return Whether or not the signature was valid
     */
    function validateSignature (
        bytes32 hash, 
        uint8 v, 
        bytes32 r, 
        bytes32 s, 
        address expected
    ) 
      public 
      pure 
      returns (bool) 
    {
        return ecrecover(
            hash, 
            v, 
            r, 
            s
        ) == expected;
    }

    /**
     * @dev Validate that the hash of a provided address was signed by the ECDSA public key associated with the specified Ethereum address
     * @param addr Address signed
     * @param pubKey Uncompressed ECDSA public key claiming to have created this signature
     * @param v v parameter of ECDSA signature
     * @param r r parameter of ECDSA signature
     * @param s s parameter of ECDSA signature
     * @return Whether or not the signature was valid
     */
    function ecdsaVerify (
        address addr, 
        bytes pubKey, 
        uint8 v, 
        bytes32 r, 
        bytes32 s
    ) 
      public 
      pure 
      returns (bool)
    {
        return validateSignature(
            sha256(abi.encodePacked(addr)), 
            v, 
            r, 
            s, 
            pubKeyToEthereumAddress(pubKey)
        );
    }

    /**
     * @dev Convert an uncompressed ECDSA public key into an Ethereum address
     * @param pubKey Uncompressed ECDSA public key to convert
     * @return Ethereum address generated from the ECDSA public key
     */
    function pubKeyToEthereumAddress (bytes pubKey) public pure returns (address) {
        return address(uint(keccak256(pubKey)) & 0x000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
    }

    /**
     * @dev Calculate the Bitcoin-style address associated with an ECDSA public key
     * @param pubKey ECDSA public key to convert
     * @param isCompressed Whether or not the Bitcoin address was generated from a compressed key
     * @return Raw Bitcoin address (no base58-check encoding)
     */
    function pubKeyToBitcoinAddress(bytes pubKey, bool isCompressed) public pure returns (bytes20) {
        /* Helpful references:
           - https://en.bitcoin.it/wiki/Technical_background_of_version_1_Bitcoin_addresses 
           - https://github.com/cryptocoinjs/ecurve/blob/master/lib/point.js
        */

        /* x coordinate - first 32 bytes of public key */
        uint256 x = uint(extract(pubKey, 0));
        /* y coordinate - second 32 bytes of public key */
        uint256 y = uint(extract(pubKey, 32)); 
        uint8 startingByte;
        if (isCompressed) {
            /* Hash the compressed public key format. */
            startingByte = y % 2 == 0 ? 0x02 : 0x03;
            return ripemd160(abi.encodePacked(sha256(abi.encodePacked(startingByte, x))));
        } else {
            /* Hash the uncompressed public key format. */
            startingByte = 0x04;
            return ripemd160(abi.encodePacked(sha256(abi.encodePacked(startingByte, x, y))));
        }
    }

    /**
     * @dev Verify a Merkle proof using the UTXO Merkle tree
     * @param proof Generated Merkle tree proof
     * @param merkleLeafHash Hash asserted to be present in the Merkle tree
     * @return Whether or not the proof is valid
     */
    function verifyProof(bytes32[] proof, bytes32 merkleLeafHash) public view returns (bool) {
        return MerkleProof.verifyProof(proof, rootUTXOMerkleTreeHash, merkleLeafHash);
    }

    /**
     * @dev Convenience helper function to check if a UTXO can be redeemed
     * @param originalAddress Raw Bitcoin address (no base58-check encoding)
     * @param satoshis Amount of UTXO in satoshis
     * @param proof Merkle tree proof
     * @return Whether or not the UTXO can be redeemed
     */
    function canRedeemUTXO(
        bytes20 originalAddress,
        uint256 satoshis,
        bytes32[] proof
    ) 
        public 
        view 
        returns (bool)
    {
        /* Calculate the hash of the Merkle leaf associated with this UTXO. */
        bytes32 merkleLeafHash = keccak256(
            abi.encodePacked(
                originalAddress,
                satoshis
            )
        );
    
        /* Verify the proof. */
        return canRedeemUTXOHash(merkleLeafHash, proof);
    }
      
    /**
     * @dev Verify that a UTXO with the specified Merkle leaf hash can be redeemed
     * @param merkleLeafHash Merkle tree hash of the UTXO to be checked
     * @param proof Merkle tree proof
     * @return Whether or not the UTXO with the specified hash can be redeemed
     */
    function canRedeemUTXOHash(bytes32 merkleLeafHash, bytes32[] proof) public view returns (bool) {
        /* Check that the UTXO has not yet been redeemed and that it exists in the Merkle tree. */
        return((redeemedUTXOs[merkleLeafHash] == false) && verifyProof(proof, merkleLeafHash));
    }

    function getRedeemAmount(uint256 amount) internal view returns (uint256 redeemed) {
        /* Convert from 8 decimals to 18 */
        uint256 satoshis = amount.mul(1e10);

        /* Weeks since launch */
        uint256 weeksSinceLaunch = block.timestamp.sub(launchTime).div(7 days);

        /* Calculate percent reduction */
        uint256 reduction = uint256(100).sub(weeksSinceLaunch.mul(2));

        /* Silly whale reduction
           If claim amount is above 1000 BHX with 18 decimals ( 1e3 * 1e18 = 1e20) */
        if (satoshis > 1e21) {
            /* If claim amount is below 100000 BHX with 18 decimals (1e5 * 1e18 = 1e23) */
            if (satoshis < 1e23) {
                /* If between 1000 and 10000, penalise by 50% to 75% linearly
                   The following is a range convert from 1000-10000 to 500-2500
                   satoshis = ((Input - InputLow) / (InputHigh - InputLow)) * (OutputHigh - OutputLow) + OutputLow
                   satoshis = ((x - 1000) / (10000 - 1000)) * (2500 - 500) + 500
                   satoshis = (2 (x - 1000))/9 + 500 */
                satoshis = satoshis
                    .sub(1e11)
                    .mul(2)
                    .div(9)
                    .add(5e10);
            } else {
                /* If greater than 10000 BHX penalise by 75% */
                satoshis = satoshis.div(4);
            }
        }

        /* 
          Calculate redeem amount in standard token decimals (1e18): 
          already has 8 decimals (1e8 * 1e10 = 1e18) 
        */
        uint256 redeemAmount = satoshis.mul(reduction).mul(1e10).div(100);

        /* Apply speed bonus */
        if(weeksSinceLaunch > 45) {
            return redeemAmount;
        }

        if(weeksSinceLaunch > 32) {
            return redeemAmount.mul(101).div(100);
        }

        if(weeksSinceLaunch > 24) {
            return redeemAmount.mul(102).div(100);
        }

        if(weeksSinceLaunch > 18) {
            return redeemAmount.mul(103).div(100);
        }

        if(weeksSinceLaunch > 14) {
            return redeemAmount.mul(104).div(100);
        }

        if(weeksSinceLaunch > 10) {
            return redeemAmount.mul(105).div(100);
        }

        if(weeksSinceLaunch > 7) {
            return redeemAmount.mul(106).div(100);
        }

        if(weeksSinceLaunch > 5) {
            return redeemAmount.mul(107).div(100);
        }

        if(weeksSinceLaunch > 3) {
            return redeemAmount.mul(108).div(100);
        }

        if(weeksSinceLaunch > 1) {
            return redeemAmount.mul(109).div(100);
        }

        return redeemAmount.mul(110).div(100);
    }

    /**
     * @dev Redeem a UTXO, crediting a proportional amount of tokens (if valid) to the sending address
     * @param satoshis Amount of UTXO in satoshis
     * @param proof Merkle tree proof
     * @param pubKey Uncompressed ECDSA public key to which the UTXO was sent
     * @param isCompressed Whether the Bitcoin address was generated from a compressed public key
     * @param v v parameter of ECDSA signature
     * @param r r parameter of ECDSA signature
     * @param s s parameter of ECDSA signature
     * @return The number of tokens redeemed, if successful
     */
    function redeemUTXO (
        uint256 satoshis,
        bytes32[] proof,
        bytes pubKey,
        bool isCompressed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) 
        public 
        returns (uint256 tokensRedeemed)
    {
        /* Check if weekly data needs to be updated */
        storeWeekUnclaimed();

        /* Disable claims after 50 weeks */
        require(block.timestamp.sub(launchTime).div(7 days) < 50);

        /* Calculate original Bitcoin-style address associated with the provided public key. */
        bytes20 originalAddress = pubKeyToBitcoinAddress(pubKey, isCompressed);

        /* Calculate the UTXO Merkle leaf hash. */
        bytes32 merkleLeafHash = keccak256(
            abi.encodePacked(
                originalAddress, 
                satoshis
            )
        );

        /* Verify that the UTXO can be redeemed. */
        require(canRedeemUTXOHash(merkleLeafHash, proof));

        /* Claimant must sign the Ethereum address to which they wish to remit the redeemed tokens. */
        require(
            ecdsaVerify(
                msg.sender, 
                pubKey, 
                v, 
                r, 
                s
            )
        );

        /* Mark the UTXO as redeemed. */
        redeemedUTXOs[merkleLeafHash] = true;

        tokensRedeemed = getRedeemAmount(satoshis);

        /* Sanity check. */
        require(totalRedeemed.add(tokensRedeemed) <= maximumRedeemable);

        /* Track total redeemed tokens. */
        totalRedeemed = totalRedeemed.add(tokensRedeemed);

        /* Credit the redeemer. */ 
        balances[msg.sender] = balances[msg.sender].add(tokensRedeemed);

        /* Increase supply */
        totalSupply_ = totalSupply_.add(tokensRedeemed);

        /* Mark the transfer event. */
        emit Transfer(address(0), msg.sender, tokensRedeemed);
        
        /* Return the number of tokens redeemed. */
        return tokensRedeemed;

    }

    /**
     * @dev Redeem a UTXO, crediting a proportional amount of tokens (if valid) to the sending address
     * @param satoshis Amount of UTXO in satoshis
     * @param proof Merkle tree proof
     * @param pubKey Uncompressed ECDSA public key to which the UTXO was sent
     * @param isCompressed Whether the Bitcoin address was generated from a compressed public key
     * @param v v parameter of ECDSA signature
     * @param r r parameter of ECDSA signature
     * @param s s parameter of ECDSA signature
     * @param referrer address of referring person
     * @return The number of tokens redeemed, if successful
     */
    function redeemUTXO (
        uint256 satoshis,
        bytes32[] proof,
        bytes pubKey,
        bool isCompressed,
        uint8 v,
        bytes32 r,
        bytes32 s,
        address referrer
    ) 
        external 
        returns (uint256 tokensRedeemed) 
    {
        /* Credit claimer */
        tokensRedeemed = redeemUTXO (
            satoshis,
            proof,
            pubKey,
            isCompressed,
            v,
            r,
            s
        );

        /* Credit referrer */
        balances[referrer] = balances[referrer].add(tokensRedeemed.div(20));

        /* Increase supply */
        totalSupply_ = totalSupply_.add(tokensRedeemed.div(20));

        return tokensRedeemed;
    }

}

/* solium-disable security/no-block-members */


contract StakeableToken is UTXORedeemableToken {

    event Mint(address indexed _address, uint _reward);

    uint256 public totalBTCCirculationAtFork;

    uint256 public stakedCoins;

    struct StakeStruct {
        uint256 stakeAmount;
        uint256 stakeTime;
        uint256 unlockTime;
        uint256 stakedCoinsAtStart;
    }

    mapping(address => StakeStruct[]) public staked;

    function compound(uint256 _principle, uint256 _periods, uint256 _interestRateTimesHundred) internal pure returns (uint256) {
        /* Calculate compound interest */
        return (_principle * (100 + _interestRateTimesHundred) ** _periods)/(100 ** _periods);
    }

    function startStake(uint256 _value, uint256 _unlockTime) external {
        address staker = msg.sender;

        /* Make sure staker has enough funds */
        require(balances[staker] >= _value);

        /* Check if weekly data needs to be updated */
        storeWeekUnclaimed();

        /* Remove balance from sender */
        balances[staker] = balances[staker].sub(_value);
        balances[address(this)] = balances[address(this)].add(_value);
        emit Transfer(staker, address(this), _value);

        /* Create Stake */
        staked[staker].push(
          StakeStruct(
            uint128(_value), 
            block.timestamp, 
            _unlockTime, 
            stakedCoins
          )
        );

        /* Add staked coins to global stake counter */
        stakedCoins = stakedCoins.add(_value);
    }

    function calculateWeAreAllSatoshiRewards(StakeStruct stake) internal view returns (uint256 rewards) {
        /* Calculate what week stake was opened */
        uint256 startWeek = stake.stakeTime.sub(launchTime).div(7 days);

        /* Calculate current week */
        uint256 weeksSinceLaunch = block.timestamp.sub(launchTime).div(7 days);

        /* Award 2% of unclaimed coins at end of every week */
        for (uint256 i = startWeek; i < weeksSinceLaunch; i++) {
            rewards = rewards.add(weekData[i].unclaimedCoins.mul(stake.stakeAmount).div(50));
        }
    }

    function calculateViralRewards(uint256 rewards) internal view returns (uint256) {
        /* Add bonus percentage to rewards from 0-10% based on adoption */
        return rewards.mul(totalRedeemed).div(totalBTCCirculationAtFork).div(10);
    }

    function calculateCritMassRewards(uint256 rewards) internal view returns (uint256) {
        /* Add bonus percentage to rewards from 0-10% based on adoption */
        return rewards.mul(totalRedeemed).div(maximumRedeemable).div(10);
    }

    function calculateStakingRewards(StakeStruct stake) internal view returns (uint256) {
        /* Base interest rate */
        uint256 interestRateTimesHundred = 100;

        /* Calculate Adoption Percent Scaler */
        uint256 scaler = stake.stakedCoinsAtStart.mul(100).div(totalSupply_);

        /* Adjust interest rate by scaler */
        interestRateTimesHundred = interestRateTimesHundred.div(scaler);

        /* Calculate Periods */
        uint256 periods = block.timestamp.sub(stake.stakeTime).div(10 days);

        /* Compound */
        uint256 compoundRound = compound(stake.stakeAmount, periods, interestRateTimesHundred);

        /* Calculate final staking rewards with time bonus */
        return compoundRound.mul(periods).div(1000).add(compoundRound).sub(stake.stakeAmount);
        
    }

    function calculateAdditionalRewards(StakeStruct stake, uint256 initRewards) internal view returns (uint256 rewards) {
        rewards = initRewards.add(calculateWeAreAllSatoshiRewards(stake));
        rewards = rewards
            .add(calculateViralRewards(rewards))
            .add(calculateCritMassRewards(rewards));

        return rewards;
    }

    function getCurrentStaked(address staker) external view returns(uint256 stakes) {
        for (uint256 i; i < staked[staker].length; i++) {
            /* Add Stake Amount */
            stakes = stakes.add(staked[staker][i].stakeAmount);
            /* Check if stake has matured */
            if (block.timestamp > staked[staker][i].unlockTime) {
                /* Calculate Rewards */
                uint256 stakingRewards = calculateStakingRewards(staked[staker][i]);
                stakes = stakes.add(calculateAdditionalRewards(staked[staker][i], stakingRewards));
            }
        }

        return stakes;
    }

    function claimStakingRewards(address staker) external {
        /* Check if weekly data needs to be updated */
        storeWeekUnclaimed();

        for (uint256 i; i < staked[staker].length; i++) {
            /* Check if stake has matured */
            if (block.timestamp > staked[staker][i].unlockTime) {
                /* Remove StakedCoins from global counter */
                stakedCoins = stakedCoins.sub(staked[staker][i].stakeAmount);

                /* Sub staked coins from contract */
                balances[address(this)] = balances[address(this)].sub(staked[staker][i].stakeAmount);
                
                /* Add staked coins to staker */
                balances[staker] = balances[staker].add(staked[staker][i].stakeAmount);

                emit Transfer(address(this), staker, staked[staker][i].stakeAmount);

                /* Calculate Rewards */
                uint256 stakingRewards = calculateStakingRewards(staked[staker][i]);
                uint256 rewards = rewards.add(calculateAdditionalRewards(staked[staker][i], stakingRewards));

                /* Award staking rewards to staker */
                balances[staker] = balances[staker].add(rewards);

                /* Award rewards to origin contract */
                balances[origin] = balances[origin].add(rewards.sub(stakingRewards));

                /* Increase supply */
                totalSupply_ = totalSupply_.add(rewards.mul(2));

                /* Remove Stake */
                delete staked[staker][i];

                emit Mint(staker, rewards);
            }
        }
    }
}



contract BitcoinHex is StakeableToken {
    string public name = "BitcoinHex"; 
    string public symbol = "BHX";
    uint public decimals = 18;

    constructor (
        address _originAddress,
        bytes32 _rootUTXOMerkleTreeHash,
        uint256 _maximumRedeemable,
        uint256 _totalBTCCirculationAtFork
    ) 
        public
    {
        launchTime = block.timestamp;
        origin = _originAddress;
        rootUTXOMerkleTreeHash = _rootUTXOMerkleTreeHash;
        maximumRedeemable = _maximumRedeemable;
        totalBTCCirculationAtFork = _totalBTCCirculationAtFork;
    }
}