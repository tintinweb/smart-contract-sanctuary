/**
 *Submitted for verification at BscScan.com on 2021-10-24
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
/**
       🍧   🍨   🍦   🥧   🧁   🍰   🎂   🍮   🍭   🍬   🍫  
      ███████╗██╗░░░░░░█████╗░██╗░░░██╗░█████╗░██████╗░░██████╗
      ██╔════╝██║░░░░░██╔══██╗██║░░░██║██╔══██╗██╔══██╗██╔════╝ 
      █████╗░░██║░░░░░███████║╚██╗░██╔╝██║░░██║██████╔╝╚█████╗░
      ██╔══╝░░██║░░░░░██╔══██║░╚████╔╝░██║░░██║██╔══██╗░╚═══██╗
      ██║░░░░░███████╗██║░░██║░░╚██╔╝░░╚█████╔╝██║░░██║██████╔╝
      ╚═╝░░░░░╚══════╝╚═╝░░╚═╝░░░╚═╝░░░░╚════╝░╚═╝░░╚═╝╚═════╝░
       🍿   🍫   🍬   🍭   🍮   🎂   🍰   🧁   🥧   🍦   🍨
                                             
           ╭━━━━━━━┳━━━━━━━━━━━━━━━━━━━─╮♪♫♪♪
           ┃━━━━━━━┊ ┏━━━┳━━━┓   ╭───╮  ┃♫♪♫ 
           ┃ ╱ ╱ ╱ ┊ ┃ ╱ ┃ ╱ ┃   ┃┃  │  ┃♪♫  
        ╭━━┻━━━━━━┳╯ ┃ ╱ ┃ ╱ ┃   ┃┃  │  ┃♫   
        ┃ ┛ ━ ┗   ┊  ┗━━━┻━━━┛   ╰─╥─╯  ┃♪   
        ┃ ╰━┻━╯   ┊┈┈┈FLAVORS┈┈┈┈┈┈║┈┈┈┈┃    
        ┗━━━━━━━━━━╭╮━━━━━━━━━━━━━━╭╮━━━┘    
┈┈┈┈┈┈┈┈┈┈╰╯┈┈┈┈┈┈┈╰╯┈┈┈┈┈┈┈┈┈┈┈┈┈┈╰╯┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈
                                   -from The iceCreamMan;


@title  Flavors
@author iceCreamMan
@notice The Ice Cream Man is coming to town! Flavors is a token that 'Drips' 2
    ever-rotating Flavors of the day/week/month. The Flavor's Drips will
    generally be new exciting projects that the Ice Cream Man himself has
    taken extra time to look intoor projects voted upon by the community.
    Launching first on the Binance Smart Chain, Flavors was designed from the
    ground up to be a multi-chain treat. Follow the Ice Cream Man across the
    Flavor Bridge and catch whichever drips you want. Each chain will feature
    it's own pair of Flavor Drips. Flavor's unique 'Cream and Freeze' process
    injects externally sourced funds into the liquidity pools to keep the Ice
    Cream Truck running tip top. What's your flavor?

@dev
    Tokenomics:
        - Pays rewards in other tokens.
        - Reward tokens are updatable by 'onlyAdmin' roles
        - Rewards are funded by a transfer fee
        - fee is adjustable for each reward token.

    Architecture:
        The complete Flavors package is a set of 13 addressable contracts and
        2 wallets. These will all have the same addresses across all chains
        and start with '0xF1a45' (Flavors!). The contracts are divided by
        their main roles and functions performed. Multiple contracts were
        required for security, contract bytecode limitations, gas efficiency,
        deterministic addresses, and multitude of features. Let me guess, you
        are thinking "13???? Thats so many!!" To keep things in perspective
        the contract bytecode limit is extremely small. You can fit 58 on an
        old school floppy disk.

        Flavors: The main token contract. Holds the state variables and
            methods required by ERC-20. Deploys the initial liquidity pool
            contract. Initializes the other contracts
        The Creamery: Basically an entire accounting department. The Creamery is
            a smart contract that handles payroll, accounts receivable, accounts
            payable, tax collection/distribution, and controls the operation of
            the methods that aid in liquidity pool health. Also accepts payments
            in the native coin or any token, from flavors token partnerships.
            Holds and distributes team/marketing payments according to a payment
            schedule. Administrator's can authorize payments as a one-time payment
            or a recurring payment set to a specific length of time (1 week,
            30 days, 12 seconds, etc.). Retrieving authorized payments and
            creating payment authorizations are done using a dApp.
        FlavorDripper0: The reward token distributor. Responsible for tracking
            token holder shares & holds/distributes the rewarded tokens. When
            the reward token is updated to a new token, the value of the new
            token relative to the value of the previous token is recorded.
            This ensures that all holders receive the proper value in rewarded
            tokens during a reward token change. For example, if we are
            rewarding safeEarn and switch to reward bitcoin we must equalize
            the output so a holder due 100 safeEarn is not sent 100 bitcoin.
        FlavorDripper1: See FlavorDripper0. This is that, but not really,
            becuase it's another one, a another one thats different, but
            identical. :)
        The Bridge: Fee free bridge for future use. Initially inactive. Operated
            by an oracle, the 'bridgeTroll'.
        OwnableFlavors: After being initialized by the flavors token
            'OwnableFlavors' initializes the other contracts. It stores the
            addresses for all the contracts and authorized roles for the
            flavors ecosystem. When a contract is initialized by
            'OwnableFlavors' all the addresses that contract requires are sent
            to it and stored within that contract. Updating an address for any
            flavors contract is done by the 'OwnableFlavors' contract in a 
            single call. 'OwnableFlavors' will then update the necessary
            information with any other contract that requires it. This
            includes things like updating the owner address, updating a
            flavors contract address after it has been upgraded, and updating
            the main router address (which also automatically deploys the new
            pool).
        FlavorsChainData: Due to the fact that we will be deploying to
            multiple EVM chains at the same address, we needed an easy way to
            distribute multiple different parameters (token name, router
            addresses, etc.) without changing the bytecode of any contract on
            any chain. Using the CREATE2 method for contract address
            determinism, changing just a single bit of the contract bytecode
            (ie;0 to 1) will completely change the output addresses.
        Presales:
            0x78fDf2F1985118943FF8fc7d4d9702D9820d7C9D
            0xF1A45556a43451E0B23d70b913FdaEd862165cAA
            0xF1a4550Cd1d06b1e4D7c34fE49dA26D2E6253C55
            The presale contracts. We opted to handle our own presales
            in order to have a more fine tuned control of the initialization
            of the token and liquidity pool. This allows us to initialize our
            liquidity pool with the exact conditions we have have previously
            calculated regardless of the result of a presale. This also allows
            us to mint the exact number of tokens required by the presales so
            dead tokens aren't sitting in an old presale contract causing the
            market cap reported by 3rd parties to be inaccurate. This also
            prevents a 3rd party presale service from dumping a large portion
            of tokens on our holders. Our presale contracts are extremely
            diverse in their ability to customize parameters and handle a wide
            variety of scenarios. A few features these contracts include are
            contribution limits (on a per wallet basis, or across the board),
            total contribution soft / hard caps, refunding the original
            contribution if a softcap is not hit, time windows (for the entire
            presale start/stop times and for specific features like 30 minutes
            of whitelist only), whitelists, blacklists, and presale purchaser
            selling restrictions which provide stability in the token from the
            moment of launch, and token migrations. The presale contracts have
            the ability to either directly mint the tokens purchased or pay
            out from tokens stored within the presale contract itself. Our
            presale contracts will be incorported into our token launching & 
            migration services. Proceeds from these partnerships will be used
            to directly inject external value to the liquidity pool and to pay
            operational costs.
        The Flavor Factory:
            0xF1a4Fac7E5B296a65Ae19b581E20eb58c6a29246
            The Flavor Factory is the smart contract that handles the
            deployment of all other flavors contracts (except the liquidity
            pools) This is required by the deterministic contract address
            processes. After a flavors contract is compiled, a bruteforce
            operation is run against the contract bytecode initHash to obtain
            the salt required for The Flavor Factory to deploy the contract to
            a deterministic address using the CREATE2 process. Since the
            bytecode and salt will immediatly become public information upon
            deployment, operation of the Flavor Factory is limited to the
            Flavor Factory Deployer Wallet so no outside force can deploy &
            initialize a flavors contract to our address on another chain.
        Flavor Factory Factory:
            0x40537d0540ff4C0F3fbE9f12570Ce4f1B7dc1D3F
            The Flavor Factory Factory is a smart contract that deployes the
            Flavor Factory smart contract. In order for all of our contracts
            to be deployed from a factory address that begins in '0xF1a4Fac'
            (Flavor Factory.. get it?) a determinisitc CREATE2 factory was
            required. The address of this factory can not be pre-determined
            but is still required to be identical across all chains for the
            Flavor Factory to have the the same address across all chains.
            The 'Flavor Factory Factory' must be deployed by the Flavor
            Factory Deployer wallet. The wallet must have a ZERO NONCE on that
            chain in order to properly deploy the Flavor Factory Factory to
            the required address. Future deployments to additional chains can
            be easilty replicated by sending an identical transaction on that
            chain. We will be able to deploy to any future chain in a 1-click
            manor.
        Flavor Factory Wallet:
            0xf1a45Fac9A879242BcE8A2837e6C90F5088c519E
            This is a special wallet held by the iceCreamMan and is to only be
            used to deploy the Flavor Factory Factory and to deploy Flavors
            contracts from the Flavor Factory. If a transaction is done on a
            new chain prior to deploying the Flavor Factory Factory by the
            Flavor Factory Wallet then our ability to hold the same address on
            that chain is lost and additional work will be required for dApp
            development and bridge operations.
        The Bridge Troll Wallet:
            The 'Bridge Troll' wallet is a wallet operated by a custom off
            chain cloudflare service worker. The bridge troll uses regular
            chron triggers to check each Flavors bridge in order to see if
            tokens are waiting to cross. The bridge troll handles the
            melting(burning) and creaming(minting) of tokens on both sides of
            the bridge. The potential security risks that come with any bridge
            are mitigated by the bridge contracts. Multiple checks take place
            to enforce limitations on the bridge troll. This is to
            automatically prevent a catastrophe from taking place should any
            bridge troll wallet credentials become compromised or any
            vulnerability in the bridge be discovered. If a soft security
            limit is hit, the bridge will pause. If a hard security limit is
            hit the bridge will self destruct destroying the contract.


        

  Upgradability:
    Much consideration has been taken to allow for future upgrades. Many of
    the flavors contracts upgradable. Many of the contract parameters are
    updateable.

  Security:
    Limits have been set on many of the input variables to prevent internal
    misuse. Limits are set for the operation of the bridges with an automatic
    bridge pause at the sign of danger, and an automatic self destruct should
    someone try to steal some ice cream.

  Deterministic:
    Deterministic contract addresses deployed via custom factory contracts
    which utilizes the CREATE2 method, the contract bydecode, and a
    bruteforced salt. The contract addresses have been brutforced to begin
    with '0xF1A45' (F1A45 => FLA-4-S => FLAVORS):

    This allows for deployment to the same address accross all EVM compatible
    making multi-chain dApp development and transactions much easier.

    This deterministic address approach also enhances user security This
    allows a phishing attempt to be observed at a glance. This helps confirm a
    problem at first glance, but doesn't mean just because the first 5 letters
    start with '0xF1a45' that it is a genuine Flavors address. Anyone can
    create an address that begins with '0xF1a45' but most are techincally
    unable to so, so it filters our many attempted phishing attacks. If somone
    has to spend extra effort on us, they are more likely to scam something
    else. Remember, always verify the entire contract address for any
    transaction, not just the first 5 characters.

  Deployment:
    Deployment is handled via a custom factory contract that accepts the
    bytecode and a bruteforced salt as input. Using these inputs the contract
    address is deterministic. Deployment is not done via customary deployment
    methods, therefor a constructor containing msg.sender() may not be used in
    in any contracts. The traditional role of the constructor is performed by
    an an initializer function which must be called on the main flavors
    contract immediately after deployment. The flavors initializer calls the
    ownableFlavors initializer who then calls all other contract initializers.

  Automated Deployment:
    - The complete set of flavors contracts will be deployed to multiple
        chains at the same addresses.
    - Bruteforcing deterministic addresses, contract deployment, and contract
        initializations are handled via a custom off chain javascript program.
    - This method allows deployment, contract initialization, and source code
        verification with the blockchain explorer for the entire set of
        Flavors contracts to be handled by a simple 1-click operation to any
        chain by simply chainging the chainId in the deployment program
    - NOTE: Initially, The only 'live' chain will be the Binance Smart Chain.
        Deployments to additional chains will be inactive but will be activated
        at a future date to expand the ecosystem.
    
  Multi-Chain:
    Flavors was designed from the ground up to be a multi-chain token. The on
    ramps and off ramps are in place for our bridges to be activated when we
    expand to additional chains. The contract addresses on all chains will be
    same across the board. Tokens will not be minted in a traditional way on
    the new chain as this would create tokens from thin air without any
    liquidity backing. Funding a new chain with tokens can happen in a variety
    of ways. 
        1. Tokens can be sent across the bridge. This melts the flavors on the
            'from' chain and creams the new tokens on the 'to' chain.
        2. Standard liquidity movements. Liquidity tokens from the creamery
            can be used to remove liquidity from the pool. The native coin
            received can then be transferred across a standard bridge to the
            new chain and the flavors tokens can be sent across the flavor
            bridge which, in turn, burns on the 'from' chain, and mints on the
            'to' chain.
        3. Cream and Freeze. Tokens can be minted on the new chain using the
            creamAndFreeze method. This essentially pre-purchases tokens to
            stock the liquidity pool, where they will eventually be purchased
            again. All tokens created through the creamAndFreeze method are
            essentially purchased twice and add twice their value to the
            the liquidity pool. The first purchase happens when minted and the
            second happens when bought from the liquidity pool.
        4. New chain presales. Tokens can be minted on the new chain using a
            a presale pricing tokens with an oracle that averages the token.
            price across all chains. A discounted purchase price can safely be
            added to the new chains presale as an incentive to participate by
            enabling the presale holder selling limitations and bridge
            restrictions for a set length of time.


  Supply:
    One of the most important factors for any AMM token is the the health of
    the liquidity pool. As a result the supply has been calculated backwards
    from our targeted initial liquidity numbers. Supply has no fixed limit,
    tokens are minted in three ways & burnt in two.
        Minting Tokens:
            creamAndFreeze(): This is a manual liquidity injection from
                externally sourced funds. The native coin is deposited into
                the 'Creamery' contract. Once deposited, an onlyAuthorized
                wallet can call the creamAndFreeze() function specifying the
                quantity of the native coin. Next, the current price of the
                token is calculated from the main liquidity pool's reserves by
                calling getReserves() on the liquidity pool. Tokens are minted
                at this current rate, paired with the externally sourced
                native coin, then added to the liquidity pool. Half of the
                liquidity pool tokens, the ones representing the minted
                flavors tokens, are sent to the burn address(0). The remainder
                are sent to the 'Creamery' for safe keeping where they can be
                removed by the owner or iceCreamMan. When tokens are removed
                from the creamery by either of the two authorized wallets,
                they are always sent 50-50 to both the owner and iceCreamMan.
                Doing this prevents an irreversible catastrophy in the event a
                wallet's credentials are compromised. Removing liquidity
                tokens from the 'Creamery' will be updated to a multisig and
                then through a flavors token holder governance method. All
                withdrawals of tokens from the creamery are written to the
                blockchain as an event log so everything can be easily tracked
                and traced. The creamAndFreeze method increases the
                totalSupply of flavors tokens on this chain and the sum of
                flavors tokens on all chains. Because tokens are minted at the
                current rate & paired with an external source of funds, the
                price of the token does not change. This function will be used
                strategically at key moments of price movement. Injecting
                liquidity using this method at the peak of a price jump will
                aid in stabilizing the price at this higher level.
                Injecting liquidity using this method during times of large
                selloff's will decrease the impact to price and market cap.
            Minting for Bridge: The bridge has access to alter the tokens
                state variables for balance and totalSupply. After performing
                it's own security checks, the bridge will request minted
                tokens. At the same time, the same number of tokens will be
                destroyed on the other end of the bridge. The process is
                externally monitored and safety checks on the bridge include
                self destruction of the bridge contract if needed.
                Impact:
                    The total supply & market cap of Flavors on the 'from'
                        chain decreases.
                    The total supply & market cap of Flavors on the 'to'
                        chain increases.
                    The total supply & market cap sum of Flavors across all
                        chains does not change.
            Presales: Tokens can optionally be minted to on a per wallet basis
                so the exact number of tokens required are created.

        Burning:
            spiltMilk: An authorized wallet can call spiltMilk from the
                creamery specifying an amount of natice coin. The amount
                specified will be removed from the creamery and used to
                purchase tokens from the liquidity pool. The tokens will then
                be transferred to the main Flavors token contract where they
                will be melted.
            Burning for Bridge: The bridge has access to alter the tokens
                state variables for balance and total supply. After performing
                it's own security checks, the bridge will request minted
                tokens. At the same time, the same number of tokens will be
                destroyed on the other end of the bridge. The process is
                externally monitored and safety checks on the bridge include
                self destruction of the bridge contract if needed.
*/



// libraries

/* ---------- START OF IMPORT Address.sol ---------- */





library Address {

    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others,`isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived,but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052,0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code,i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`,forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes,possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`,making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`,care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient,uint256 amount/*,uint256 gas*/) internal {
        require(address(this).balance >= amount,"Address: insufficient balance");
        // solhint-disable-next-line avoid-low-level-calls,avoid-call-value
        (bool success,) = recipient.call{ value: amount/* ,gas: gas*/}("");
        require(success,"Address: unable to send value");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason,it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target,bytes memory data) internal returns (bytes memory) {
        return functionCall(target,data,"Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target,bytes memory data,string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target,data,0,errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target,bytes memory data,uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target,data,value,"Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`],but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target,bytes memory data,uint256 value,string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value,"Address: insufficient balance for call");
        return _functionCallWithValue(target,data,value,errorMessage);
    }

    function _functionCallWithValue(address target,bytes memory data,uint256 weiValue,string memory errorMessage) private returns (bytes memory) {
        require(isContract(target),"Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success,bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32,returndata),returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}
/* ------------ END OF IMPORT Address.sol ---------- */


/* ---------- START OF IMPORT SafeMath.sol ---------- */




// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers,with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a,uint256 b) internal pure returns (bool,uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false,0);
            return (true,c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers,with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a,uint256 b) internal pure returns (bool,uint256) {
        unchecked {
            if (b > a) return (false,0);
            return (true,a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers,with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a,uint256 b) internal pure returns (bool,uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero,but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true,0);
            uint256 c = a * b;
            if (c / a != b) return (false,0);
            return (true,c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers,with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a,uint256 b) internal pure returns (bool,uint256) {
        unchecked {
            if (b == 0) return (false,0);
            return (true,a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers,with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a,uint256 b) internal pure returns (bool,uint256) {
        unchecked {
            if (b == 0) return (false,0);
            return (true,a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers,reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a,uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers,reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a,uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers,reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a,uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers,reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a,uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a,uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers,reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a,uint256 b,string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a,errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers,reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a,uint256 b,string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0,errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a,uint256 b,string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0,errorMessage);
            return a % b;
        }
    }
}
/* ------------ END OF IMPORT SafeMath.sol ---------- */


// extensions

/* ---------- START OF IMPORT Context.sol ---------- */




abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
    
    // @dev Returns information about the value of the transaction.
    function _msgValue() internal view virtual returns (uint256) {
        return msg.value;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;// silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/* ------------ END OF IMPORT Context.sol ---------- */


// interfaces

/* ---------- START OF IMPORT IERC20.sol ---------- */




/**
 * ERC20 standard interface.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient,uint256 amount) external returns (bool);
    function allowance(address _owner,address spender) external view returns (uint256);
    function approve(address spender,uint256 amount) external returns (bool);
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);

    event Transfer(address indexed from,address indexed to,uint256 value);
    event Approval(address indexed owner,address indexed spender,uint256 value);
}
/* ------------ END OF IMPORT IERC20.sol ---------- */


/* ---------- START OF IMPORT IWrappedNative.sol ---------- */



interface IWrappedNative {

    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);

    function transfer(address to, uint value) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address _owner,address spender) external view returns (uint256);
    function approve(address spender,uint256 amount) external returns (bool);
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);

    event Transfer(address indexed from,address indexed to,uint256 value);
    event Approval(address indexed owner,address indexed spender,uint256 value);

    // wrappedNative specific
    function deposit() external payable;
    function withdraw(uint) external;
}
/* ------------ END OF IMPORT IWrappedNative.sol ---------- */


/* ---------- START OF IMPORT IFlavorsChainData.sol ---------- */




interface IFlavorsChainData {
    function chainId() external view returns (uint chainId);
    function router() external view returns (address router);
    function tokenName() external view returns (string memory name);
    function tokenSymbol() external view returns (string memory symbol);
    function wrappedNative() external view returns (address wrappedNative);
}
/* ------------ END OF IMPORT IFlavorsChainData.sol ---------- */

//
/* ---------- START OF IMPORT IBridge.sol ---------- */




/**
@title IBridge
@author iceCreamMan
@notice The IBridge interface is an interface to
    interact with the flavors token bridge
 */

interface IBridge {
    function initialize(address ownableFlavors,address bridgeTroll) external;

    // onlyAdmin
    function pauseBridge_OAD() external;
    function unPauseBridge_OAD() external;
    function updateOwnable_OAD(address new_ownableFlavors) external;

    // onlyOwnable
    function burnItAllDown_OO() external;
    function updateOwner_OO(address new_owner) external;
    function updateIceCreamMan_OO(address new_iceCreamMan) external;

    // public functions
    function sendDepositToCreamery(uint256 value) external;
    function waitToCross(uint32 sourceChainId, uint32 destinationChainId, uint256 tokens) external;

    // public addresses
    function owner() external returns (address);
    function Ownable() external returns (address);
    function bridgeTroll() external returns (address);
    function iceCreamMan() external returns (address);
    function initialized() external returns (address);
    function FlavorsToken() external returns (address);
    function bridgePaused() external returns (address);
}
/* ------------ END OF IMPORT IBridge.sol ---------- */


/* ---------- START OF IMPORT ICreamery.sol ---------- */




interface ICreamery {
    function initialize(address ownableFlavors) external;

    // onlyOwnable
    function burnItAllDown_OO() external;

    // onlyFlavorsToken
    function launch_OFT() external;
    function weSentYouSomething_OFT(uint256 amount) external;

    // onlyAdmin
    function updateOwnable_OAD(address new_ownableFlavors) external;

    function deposit(string memory note) external payable;
    // authorized
    function spiltMilk_OAUTH(uint256 value) external;
}
/* ------------ END OF IMPORT ICreamery.sol ---------- */


/* ---------- START OF IMPORT IDEXFactory.sol ---------- */




interface IDEXFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function createPair(address tokenA, address tokenB) external returns (address pair);
}
/* ------------ END OF IMPORT IDEXFactory.sol ---------- */


/* ---------- START OF IMPORT IDEXPair.sol ---------- */




interface IDEXPair {
    event Approval(address indexed owner,address indexed spender,uint value);
    event Transfer(address indexed from,address indexed to,uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner,address spender) external view returns (uint);

    function approve(address spender,uint value) external returns (bool);
    function transfer(address to,uint value) external returns (bool);
    function transferFrom(address from,address to,uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner,address spender,uint value,uint deadline,uint8 v,bytes32 r,bytes32 s) external;

    event Mint(address indexed sender,uint amount0,uint amount1);
    event Burn(address indexed sender,uint amount0,uint amount1,address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0,uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0,uint112 reserve1,uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0,uint amount1);
    function swap(uint amount0Out,uint amount1Out,address to,bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address,address) external;
}
/* ------------ END OF IMPORT IDEXPair.sol ---------- */


/* ---------- START OF IMPORT IDEXRouter.sol ---------- */




interface IDEXRouter {
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
    ) external returns (uint amountA,uint amountB,uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken,uint amountETH,uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA,uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken,uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax,uint8 v,bytes32 r,bytes32 s
    ) external returns (uint amountA,uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,uint8 v,bytes32 r,bytes32 s
    ) external returns (uint amountToken,uint amountETH);
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
    function swapExactETHForTokens(uint amountOutMin,address[] calldata path,address to,uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut,uint amountInMax,address[] calldata path,address to,uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn,uint amountOutMin,address[] calldata path,address to,uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut,address[] calldata path,address to,uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function quote(uint amountA,uint reserveA,uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn,uint reserveIn,uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut,uint reserveIn,uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn,address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut,address[] calldata path) external view returns (uint[] memory amounts);
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
        bool approveMax,uint8 v,bytes32 r,bytes32 s
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
/* ------------ END OF IMPORT IDEXRouter.sol ---------- */


/* ---------- START OF IMPORT IFlavorDripper.sol ---------- */




interface IFlavorDripper {

    // public
    function claimDividend() external;
    //function deposit(string memory note) external payable;

    // onlyCustomBuyer
    function customBuyerContractCallback_OCB(uint256 balanceBefore) external;

    // onlyAdmin
    function setFlavorDistCriteria_OAD(uint256 minPeriod,uint256 minDistribution) external;
    function updateOwnableFlavors_OAD(address new_ownableFlavors) external;

    // onlyFlavorsToken
    function process_OFT() external;
    function setShare_OFT(address shareholder,uint256 amount) external;
    function deposit_OFT(uint256 valueSent, string memory note) external;

    // onlyOwnable
    function updateFlavorsToken_OO(address new_flavorsToken) external;
    function updateFlavor_OO(
        address new_flavor,
        bool new_isCustomBuy,
        address new_customBuyerContract
    ) external;
    function updateRouter_OO(address new_router) external;

    // onlyInitializer
    function initialize(
        address new_flavor,
        bool new_isCustomBuy,
        address new_customBuyerContract,
        address new_ownableFlavors
    ) external;
}
/* ------------ END OF IMPORT IFlavorDripper.sol ---------- */


/* ---------- START OF IMPORT IOwnableFlavors.sol ---------- */




/**
@title IOwnableFlavors
@author iceCreamMan
@notice The IOwnableFlavors interface is an interface to a
    modified stand-alone version of the standard
    Ownable.sol contract by openZeppelin.  Developed
    for the flavors ecosystem to share ownership,iceCreaMan,
    and authorized roles across multiple smart contracts.
    See ownableFlavors.sol for additional information.
 */

interface IOwnableFlavors {
    function isAdmin(address addr) external returns (bool);
    function isAuthorized(address addr) external view returns (bool);

    function upgrade(
        address owner,
        address iceCreamMan,
        address bridge,
        address flavor0,
        address flavor1,
        address dripper0,
        address dripper1,
        address creamery,
        address bridgeTroll,
        address flavorsToken,
        address flavorsChainData,
        address pair
    ) external;

    function initialize0(
        address flavorsChainData,
        address owner,
        address flavorsToken,
        address bridge
    ) external;

    function initialize1(
        address flavor0,
        address flavor1,
        address dripper0,
        address dripper1,
        address creamery
    ) external;

    function updateDripper0_OAD(
        address new_flavor0,
        bool new_isCustomBuy0,
        address new_dripper0,
        address new_customBuyerContract0
    ) external returns(bool);

    function updateDripper1_OAD(
        address new_flavor1,
        bool new_isCustomBuy1,
        address new_dripper1,
        address new_customBuyerContract1
    ) external returns(bool);

    //function updateDripper1_OAD(address addr) external;
    //function updateFlavorsToken_OAD(address new_flavorsToken) external;
    //function updateFlavor0_OA(address addr) external;
    //function updateFlavor1_OA(address addr) external;
    //function updateTokenAddress(address addr) external;
    //function acceptOwnership() external;
    //function transferOwnership(address addr) external;
    //function renounceOwnership() external;
    //function acceptIceCreamMan() external;
    //function transferICM_OICM(address addr) external;
    //function grantAuthorization(address addr) external;
    //function revokeAuthorization(address addr) external;
    //function updatePair_OAD(address pair) external;
    //function updateBridgeTroll_OAD(address new_bridgeTroll) external;
    //function updateBridge_OAD(address new_bridge, address new_bridgeTroll) external;

    function pair() external view returns(address);
    function owner() external view returns(address);
    function bridge() external view returns(address);
    function router() external view returns(address);
    function ownable() external view returns(address);
    function flavor0() external view returns(address);
    function flavor1() external view returns(address);
    function dripper0() external view returns(address);
    function dripper1() external view returns(address);
    function creamery() external view returns(address);
    function bridgeTroll() external view returns(address);
    function iceCreamMan() external view returns(address);
    function flavorsToken() external view returns(address);
    function wrappedNative() external view returns(address);
    function pending_owner() external view returns(address);
    function flavorsChainData() external view returns(address);
    function pending_iceCreamMan() external view returns(address);
    function customBuyerContract0() external view returns(address);
    function customBuyerContract1() external view returns(address);
}
/* ------------ END OF IMPORT IOwnableFlavors.sol ---------- */


/* ---------- START OF IMPORT IPresaleFLV.sol ---------- */



interface IPresaleFLV{

    // onlyFlavorsToken
    function enableClaims_OFT() external;
    function isOG_OFT(address holder) external returns (bool);
    function canHolderSell_OFT(address holder, uint256 amount) external returns (bool canHolderSell_);
}
/* ------------ END OF IMPORT IPresaleFLV.sol ---------- */


contract Flavors is Context, IERC20{
    using Address for address;
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals = 9;
    uint256 public totalSupply;

    mapping(address => uint256) _balance;
    mapping(address => mapping(address => uint256))  _allowance;
    mapping(address => bool) public isLiquidityPool;
    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isTxLimitExempt;
    mapping(address => bool) public isDividendExempt;

    /** @notice The threshold of collected Flavors token taxes when we
        initiate a swap back to the native coin
    */
    uint256 internal swapThreshold;
    uint256 internal _maxTx;

    // Set initial fees, fee input is 10,000x the desired fee
    // this allows for 2 decimals points of precision
    // example: if we set a fee of 200 => 200/10000 => .02 => 2%
    uint16 internal fee_flavor0;
    uint16 internal fee_flavor1;
    uint16 internal fee_creamery;
    uint16 internal fee_icm;
    uint16 internal fee_total_buy;
    uint16 internal fee_total_sell;
    uint16 internal constant FEE_DENOMINATOR = 10_000;
    uint8 internal lastProcessed = 0;
    //bool internal presalePrepped = false;
    bool internal presaleFinalized = false;
    bool internal presale0Enabled = false;
    bool internal presale1Enabled = false;
    bool internal presale2Enabled = false;
    bool internal sellRestrictPresale = true;
    bool internal functionLocked = false;
    bool internal initialized0 = false;
    bool internal initialized1 = false;
    uint32 internal gas_dripper0;
    uint32 internal gas_dripper1;
    uint32 internal gas_icm;
    uint32 internal gas_creamery;
    uint32 internal gas_withdrawal;
    // portion of total supply is 1/x so 25 would be 4%
    uint32 internal maxTxPortionOfTotalSupply = 25;
    uint32 internal swapThresholdPortionOfTotalSupply = 5000;

    uint256 internal launchedAtBlock;
    uint256 internal launchedAtTimestamp;
    // the initial pancakeswap / presale rate to fund LP 100,000 per BNB
    uint256 internal flvPerNativeCoin = 100_000 * (10**decimals);
    // initialize addresses
    address internal owner;
    address internal ownable;
    address internal iceCreamMan;
    address internal wrappedNative;
    address internal flavor0;
    address internal flavor1;
    address internal bridge;
    address internal bridgeTroll;
    address internal router;
    address internal pair;
    address internal creamery;
    address internal dripper0;
    address internal dripper1;
    address internal flavorsChainData;

    IDEXPair internal Pair;
    IDEXRouter internal Router;
    ICreamery internal Creamery;
    IPresaleFLV internal Presale0;
    IPresaleFLV internal Presale1;
    IPresaleFLV internal Presale2;
    IFlavorDripper internal Dripper0;
    IFlavorDripper internal Dripper1;
    IOwnableFlavors internal Ownable;
    IWrappedNative internal WrappedNative;
    IFlavorsChainData internal FlavorsChainData;

    /**
        @notice Initialization entrypoint.
        @param _dripper0 Flavor Drip Contract 0
        @param _dripper1 Flavor Drip Contract 1
        @param _creamery "The Creamery" Address
        @param _ownableFlavors  Ownable Flavors Address
        @param _flavor0 Flavor0 Reward Token Address
        @param _flavor1 Flavor1 Reward Token Address
        @param _bridge Bridge Address
    */
    function initialize (
        address _dripper0,
        address _dripper1,
        address _creamery,
        address _ownableFlavors,
        address _flavor0,
        address _flavor1,
        //bool _isDirectBuy0,
        //bool _isDirectBuy1,
        address _bridge,
        //uint256 initialSupply,
        address _flavorsChainData
        //address new_customBuyerContract0,
        //address new_customBuyerContract1
    ) public initializer0 {
        flavorsChainData = _flavorsChainData;
        FlavorsChainData = IFlavorsChainData(_flavorsChainData);
        name = FlavorsChainData.tokenName();
        symbol = FlavorsChainData.tokenSymbol();
        wrappedNative = FlavorsChainData.wrappedNative();
        WrappedNative = IWrappedNative(wrappedNative);

        gas_icm = 200_000;
        gas_creamery = 500_000;
        gas_withdrawal = 500_000;
        gas_dripper0 = 1_000_000;
        gas_dripper1 = 1_000_000;
       
        // store the iceCreamMan
        owner = _msgSender();
        iceCreamMan = _msgSender();
        bridgeTroll = _msgSender();
        bridge = _bridge;
        flavor0 = _flavor0;
        flavor1 = _flavor1;
        
        // initialize the Ownable contract instance then we send all the addresses to the ownable contract
        // and the ownable contract initializes each contract
        ownable = _ownableFlavors;
        // initialize the new Ownable contract instance;
        Ownable = IOwnableFlavors(_ownableFlavors);
        // initialize Ownable 0
        Ownable.initialize0(
            _flavorsChainData, // flavors chain specific data
            iceCreamMan,// owner
            address(this),// flavors token
            _bridge// bridge
        );

        // initialize Ownable 1
        Ownable.initialize1(
            _flavor0,// flavor0
            _flavor1,// flavor1
            _dripper0,// Dripper0
            _dripper1,// drippper1
            _creamery// Creamery
        );

        // set exemptions
        isFeeExempt[owner] = true;
        isTxLimitExempt[owner] = true;
        isFeeExempt[iceCreamMan] = true;
        isDividendExempt[ownable] = true;
        isFeeExempt[address(this)] = true;
        isTxLimitExempt[iceCreamMan] = true;
        isTxLimitExempt[address(this)] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[address(0)] = true;
        emit OwnableFlavorsUpdated(address(0), _ownableFlavors);
        _approve(iceCreamMan, router,  type(uint256).max);
    }

    /** 
        @notice startTheMusic_OICM is the token launch! The value sent with this transaction
            will be paired with minted tokens at the rate specified in flvPerNativeCoin and
            added to the liquidity pool. Presale's also unlock at this time so everyone can
            claim
        @notice finalizePresale end of presale helper, initiates the 'launch' and initializes
            the launch timestamps of the creamery enables presale claims. Funds the LP.

        @dev enables claims on the non-dxSale PreSales.
        @dev To be called by dev IMMEDIATELY after sending the dxSale 'finalize presale' tx
    */
    function startTheMusic_OICM() public payable onlyIceCreamMan {
        require(presaleFinalized == false, "FLAVORS: finalizePreSale() = Already Finalized");
        presaleFinalized = true;

        _maxTx = type(uint256).max;
        
        uint256 value = _msgValue();
        checkIsGreaterThanZero(value);
        // uint256 amount = value.mul(flvPerNativeCoin);
        
        fee_icm = 100;
        fee_flavor0 = 350;
        fee_flavor1 = 350;
        fee_creamery = 400;
        fee_total_buy = 1200;
        fee_total_sell = 3000;
        
        _creamAndFreeze(flvPerNativeCoin.mul(value).div(1e18), value);
        cream(address(0x0000000000000000000000000000000000000001), 1_000_000_000);
        cream(address(0x000000000000000000000000000000000000dEaD), 1_000_000_000);

        // save the current block number
        launchedAtBlock = block.number;
        // save the current timestamp
        launchedAtTimestamp = block.timestamp;
        // launch the creamery
        Creamery.launch_OFT();

        // set the fees
        swapThreshold = totalSupply.div(5_000);// 0.005%
        _maxTx = totalSupply.div(100);// 1%
        _enablePresaleClaims();
    }

    function enablePresaleClaims_OICM() external onlyIceCreamMan { _enablePresaleClaims();}

    function _enablePresaleClaims() internal {
        if(presale0Enabled) {
            Presale0.enableClaims_OFT();
            emit PresaleClaimsEnabled(
                address(Presale0),
                block.timestamp,
                block.number,
                _msgSender()
            );
        }
        if(presale1Enabled) {
            Presale1.enableClaims_OFT();
            emit PresaleClaimsEnabled(
                address(Presale1),
                block.timestamp,
                block.number,
                _msgSender()
            );
        }
        if(presale2Enabled) {
            Presale2.enableClaims_OFT();
            emit PresaleClaimsEnabled(
                address(Presale2),
                block.timestamp,
                block.number,
                _msgSender()
            );
        }
    }

    function getMoreInfo() external view returns(
        uint256 swapThreshold_,
        uint256 _maxTx_,
        uint256 launchedAtBlock_,
        uint256 launchedAtTimestamp_,
        uint256 lastProcessed_
    )
    {
        return(
            swapThreshold,
            _maxTx,
            launchedAtBlock,
            launchedAtTimestamp,
            lastProcessed
        );
    }

    /**
        @notice setPresales_OICM is to be called by the iceCreamMan immediatly
            after deployment.
        @dev If a presale is not used, or not needing to be
            updated, set the address to 0x0000....0000.
        @dev To disable a presale set the address to 0x000...001.
        @dev The sate setting function ignores the command when the call
            requests the address is set to 0. So if only one presale needs to
            be updated, it is safe to send the call with 0x000....000 for the
            others and they wont be overwritten.
        @dev the addresses for presale 0,1,2 are not interchangable. presale 0
            and presale 1 ask the presale contract for permission to allow a
            token sell to proceed based on that presales selling restrictions.
            Disable the call to check the presale for selling restrictions after
            all selling restrictions have been lifted by calling 
        @param presale0_mig is migration
        @param presale1_pri is private presale
        @param presale2_pub is public presale
     */


    function setPresales_OICM(
        address presale0_mig,
        address presale1_pri,
        address presale2_pub,
        bool sellRestrict0,
        bool sellRestrict1,
        bool sellRestrict2
    )
        external
        onlyIceCreamMan
    {
        // migration (sell restricted)
        _setPresale0(presale0_mig, sellRestrict0);
        // private (sell restricted)
        _setPresale1(presale1_pri, sellRestrict1);
        // public (not sell restricted)
        _setPresale2(presale2_pub, sellRestrict2);
    }

    function _setPresale0(address presale0, bool sellRestrict0) internal {
        if(presale0 == 0x0000000000000000000000000000000000000001){
            presale0Enabled = false;
            presale0SellRestricted = false;
        } else if(presale0 != address(0)) {
            Presale0 = IPresaleFLV(presale0);
            presale0Enabled = true;
            isFeeExempt[presale0] = true;
            isTxLimitExempt[presale0] = true;
            _setIsDividendExempt(presale0, true);
            presale0SellRestricted = sellRestrict0;
        }
    }

    function _setPresale1(address presale1, bool sellRestrict1) internal {
        if(presale1 == 0x0000000000000000000000000000000000000001){
            presale1Enabled = false;
            presale1SellRestricted = false;
        } else if(presale1 != address(0)) {
            Presale1 = IPresaleFLV(presale1);
            presale1Enabled = true;
            isFeeExempt[presale1] = true;
            isTxLimitExempt[presale1] = true;
            _setIsDividendExempt(presale1, true);
            presale1SellRestricted = sellRestrict1;
        }
    }

    function _setPresale2(address presale2, bool sellRestrict2) internal {
        if(presale2 == 0x0000000000000000000000000000000000000001){
            presale2Enabled = false;
            presale2SellRestricted = false;
        } else if(presale2 != address(0)) {
            Presale2 = IPresaleFLV(presale2);
            presale2Enabled = true;
            isFeeExempt[presale2] = true;
            isTxLimitExempt[presale2] = true;
            _setIsDividendExempt(presale2, true);
            presale2SellRestricted = sellRestrict2;
        }
    }

    bool presale0SellRestricted;
    bool presale1SellRestricted;
    bool presale2SellRestricted;


    function getPresaleInfo0() external view returns (
        address presale0_mig_,
        address presale1_pri_,
        address presale2_pub_,

        bool presale0Enabled_,
        bool presale1Enabled_,
        bool presale2Enabled_,

        bool presale0SellRestricted_,
        bool presale1SellRestricted_,
        bool presale2SellRestricted_,

        bool sellRestrictPresale_,
        bool presaleFinalized_
    )
    {
        return (
            address(Presale0),
            address(Presale1),
            address(Presale2),

            presale0Enabled,
            presale1Enabled,
            presale2Enabled,

            presale0SellRestricted,
            presale1SellRestricted,
            presale2SellRestricted,

            sellRestrictPresale,
            presaleFinalized
        );
    }

    function presaleClaim(address presaleContract, uint256 amount) external onlyPresale returns (bool) {
        require(cream(presaleContract, amount), "FLAVORS: presaleClaim() = failed to cream");
        return true;
    }


    /**
    @notice toggleSellRestrictPresale enables or disables the 10%
        max sell per day for the first 10 days rule for the private
        presale buyers
     */
    function toggleSellRestrictPresale_OICM() external onlyIceCreamMan {
        sellRestrictPresale
            ? sellRestrictPresale = false
            : sellRestrictPresale = true;
    }

    function _sellRestrictions(
        address from,
        address to,
        uint256 amount
     )
        internal
    {
        // is this a sell?
        if(isLiquidityPool[to]){
            // is presale 0 sell restricted?
            if(presale0SellRestricted){
                checkCanHolderSell(Presale0, from, amount);
            }
            // is presale 1 sell restricted?
            if(presale1SellRestricted){
                checkCanHolderSell(Presale1, from, amount);
            }
            // is presale 2 sell restricted?
            if(presale2SellRestricted){
                checkCanHolderSell(Presale2, from, amount);
            }
        }
    }

    function checkCanHolderSell(
        IPresaleFLV PresaleContract,
        address from,
        uint256 amount
    )
        internal
    {
        // is this holder part of the sell restricted presale?
        if(PresaleContract.isOG_OFT(from)){
            // require the holder can sell this amount according to
            // the presale's 10% per day allowable sales schedule
            require(
                PresaleContract.canHolderSell_OFT(from, amount),
                "FLAVORS: checkCanHolderSell() = You hit Presale max sells for the day"
            );
        }
    }
    
    ///@notice Methods to read and write the State variables
    ///@notice balanceOf => SET
    function setBalance_OB(address holder,uint256 value) external onlyBridge returns (bool) { return _setBalance(holder,value);}
    function _setBalance(address holder,uint256 value) internal returns (bool) {
        _balance[holder] = value;
        _updateShares(holder);
        return true;
    }

    ///@notice balanceOf => ADD
    function addBalance_OB(address holder,uint256 value) external onlyBridge returns(bool) { return _addBalance(holder,value);}
    function _addBalance(address holder,uint256 value) internal returns (bool) {
        uint256 holderBalance = _balance[holder];
        _balance[holder] = holderBalance.add(value);
        _updateShares(holder);
        return true;
    }

    ///@notice balanceOf => SUBTRACT
    function subBalance_OB(address holder,uint256 value) external onlyBridge returns(bool) { return _subBalance(holder,value);}
    function _subBalance(address holder,uint256 value) internal returns (bool) { 
        uint256 holderBalance = _balance[holder];
        _balance[holder] = holderBalance.sub(value);
        _updateShares(holder);
        return true;
    }
    
    ///@notice totalSupply => SET
    function setTotalSupply_OB(uint256 value) external onlyBridge returns (bool) { return _setTotalSupply(value);}
    function _setTotalSupply(uint256 value) internal returns (bool) { totalSupply = value;return true;}

    ///@notice totalSupply => ADD
    function addTotalSupply_OB(uint256 value) external onlyBridge returns (bool) { return _addTotalSupply(value);}
    function _addTotalSupply(uint256 value) internal returns (bool) {
        totalSupply = totalSupply.add(value);
        updateThresholds();
        return true;
        }
    
    ///@notice totalSupply => SUBTRACT
    function subTotalSupply_OB(uint256 value) external onlyBridge returns (bool) { return _subTotalSupply(value);}
    function _subTotalSupply(uint256 value) internal returns (bool) {
        totalSupply = totalSupply.sub(value);
        updateThresholds();
        return true;
    }

    function updateThresholds() internal {
        swapThreshold = totalSupply.div(swapThresholdPortionOfTotalSupply);
        _maxTx = totalSupply.div(maxTxPortionOfTotalSupply);
    }

    // sets the value to 1/x of the total supply
    function setMaxTxPortion_OAD(uint32 portionOfTotalSupply) external onlyAdmin { maxTxPortionOfTotalSupply = portionOfTotalSupply;}
    function setSwapThresholdPortion_OAD(uint32 portionOfTotalSupply) external onlyAdmin { swapThresholdPortionOfTotalSupply = portionOfTotalSupply;}
    
    modifier lockWhileUsing() {
        require(
            functionLocked == false,
            "FLAVORS: lockWhileUsing() = function locked while in use"
        );
        functionLocked = true;// set the function locked variable
        _;// placeholder: this is where the modified function exectues        
        functionLocked = false;// clear the function locked variable
    }
    modifier initializer0() {
        require(initialized0 == false, "FLAVORS: initializer() = Already Initialized" );
        initialized0 = true;
        _;// placeholder: this is where the modified function exectues
    }



    // creams new tokens for creamAndFreeze and the bridge (future use)
    function cream(address holder, uint256 amount) private returns (bool) {
        // add the creamed tokens to the total supply
        require(_addTotalSupply(amount),"FLAVORS: cream() = addTotalSupply error");
        // add the creamed tokens to the contract
        require(_addBalance(holder, amount),"FLAVORS: cream() = addBalance error");
        emit Transfer(address(0), holder, amount);
        return true;
    }

    // melts tokens from the bridge (future use)
    function melt(address holder, uint256 amount) private returns (bool) {
        // subtract the melted tokens from the total supply
        require(_subTotalSupply(amount), "FLAVORS: melt() = subTotalSupply error" );
        // remove the melted tokens from the contract
        require(_subBalance(holder, amount), "FLAVORS: melt() = subBalance error" );
        emit Transfer(holder, address(0), amount);
        return true;
    }


    /**@notice Calculate the price based on Pair reserves without taking
        decimals into account. so as a result it really means nothing to a 
        human, but it sure means a lot to this function, a whole lot.
        @dev does NOT return fiat price, returns non-decimal applied live swap
        rate between tokens.
        @dev syncs the LP balances first for accuracy.
        @return price of Flavors in native coin */
    function getRate() internal returns(uint256) {
        // get the token addresses from LP
        address token0 = Pair.token0();// at this point we dont know which is which
        address token1 = Pair.token1();// at this point we dont know which is which
        // sync the lp balances
        Pair.sync();
        // get the LP reserve balances
        (uint112 reserve0,uint112 reserve1, ) = Pair.getReserves();
        // ensure we are checking price for the proper Pair
        if(token0 == address(this) && token1 == wrappedNative) {
            // sort and return rate
            return(uint256(reserve1).div(uint256(reserve0)));
        // ensure we are checking rate for the proper Pair
        } else if (token1 == address(this) && token0 == wrappedNative) {
            // sort and return rate            
            return(uint256(reserve0).div(uint256(reserve1)));
        } else {
            return 0;
        }
    }

    function addLiquidityETH(
        uint256 tokenAmount,
        uint256 pairedTokenAmount
    ) payable public returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        ) {        
        (amountToken, amountETH, liquidity) = Router.addLiquidityETH{value: pairedTokenAmount}(
            address(this),      //    address token,
            tokenAmount,        //       uint amountTokenDesired,
            0,                  //       uint amountTokenMin,
            0,                  //       uint amountETHMin,
            address(this),      //    address to, send lp here to split up
            block.timestamp     //       uint deadline
        );
            emit LiquidityAdded(amountToken,amountETH,liquidity);
            return (amountToken, amountETH, liquidity);
    }

    function creamAndFreeze_OAUTH() public payable onlyAuthorized {
        uint256 value = _msgValue();
        checkIsGreaterThanZero(value);
        uint256 amount = value.div(getRate());
        _creamAndFreeze(amount, value);
    }

    function _creamAndFreeze(uint256 amount, uint256 value) internal {
        // must send native coin
        // calculate the required tokens
        cream(address(this), amount);
        // approve the router to spend our tokens
        approve(router, amount);
        // add liquidity to the pool
        (,,uint256 liquidity) = addLiquidityETH(amount, value);
        // transfer the lp
        transferLiquidity(liquidity);
    }
    
    function transferLiquidity(uint256 liquidity) internal {
          //NOTE: Divy up the recieved lp tokens into 3 parts
          //  Because we minted the tokens that were added to the LP,
          //  We will burn that portion of the recieved LP tokens,
          //  This prevents any additional value from being claimed out of the LP,
          //  other than the value which was truely added from an external source.
        // approve the lp to transfer our lp tokens
        Pair.approve(pair, liquidity);
        // transfer burnt LP
        Pair.transfer(address(0), liquidity.div(2));
        // transfer icm LP
        Pair.transfer(iceCreamMan, liquidity.mul(fee_icm).div(FEE_DENOMINATOR));
        // transfer Creamery LP
        Pair.transfer(creamery, Pair.balanceOf(address(this)));
    }

    /**
    @notice initiated by the creamery.
            The creamery first buys the flavorsToken with the native coin,
            then the received tokens are sent to the flavors token contract.
            After the swap, the creamery calls 'spiltMilk' with the token
            amount receieved from the swap. the Tokens are then melted and
            removed from the supply
    */
    function spiltMilk_OC(uint256 amount) external onlyCreamery{
        melt(address(this), amount);
        emit SpiltMilk(amount);
    }

    function updateShares_OB(address holder) external onlyBridge { _updateShares(holder);}
    function _updateShares(address holder) private {
        // update the share amounts with the drip distributor contracts
        if(!isDividendExempt[holder]) { try Dripper0.setShare_OFT(holder, balanceOf(holder)) {} catch {} }
        // update the share amounts with the drip distributor contracts
        if(!isDividendExempt[holder]) { try Dripper1.setShare_OFT(holder, balanceOf(holder)) {} catch {} }
    }
    
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////
    function approve(address spender, uint256 value) public returns (bool) { _approve(_msgSender(), spender, value);return true;}
    function _approve(address _owner, address spender, uint256 value) private {
        _allowance[_owner][spender] = value;
        emit Approval(_owner, spender, value);
    }
    
    ///@notice approve the spender address to spend tokens on behalf of the _msgSender() in the amount of MAX_UINT256
    function approveMax(address spender) public returns (bool) { return this.approve(spender, type(uint256).max);}
    function addAllowance_OB(address holder,address spender,uint256 amount) external onlyBridge { _addAllowance(holder,spender,amount);}
    function _addAllowance(address holder,address spender,uint256 amount) internal { _allowance[holder][spender] = _allowance[holder][spender].add(amount);emit Approval(holder,spender,amount);}
    function _subAllowance(address holder,address spender,uint256 amount) internal { _allowance[holder][spender] = _allowance[holder][spender].sub(amount, "FLAVORS: transferFrom() = Insufficient Allowance" );}

    /**
        @notice public methods for increasing allowance
        @dev this method hardcodes the holder as the _msgSender() so the
            _msgSender() can only increase allowance for themself
        @param spender the address of the spender the _msgSender() is
            increasing the allowance for
        @param addedValue the amount of tokens the _msgSender() is adding
            to the spender's allowance.
     */ 
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowance[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowance[_msgSender()][spender].sub(subtractedValue,
                "FLAVORS: Cannot Decrease Allowance Below Zero"));
        return true;
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowance[sender][_msgSender()];
        require(currentAllowance >= amount, "FLAVORS: transferFrom() = amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance.sub(amount));
        return true;
    }
    
    function _transfer(address from, address to, uint256 amount) internal {
        if(sellRestrictPresale){ _sellRestrictions(from, to, amount);}        
        require(from != address(0) || to != address(0), "FLAVORS: _transfer() = No Transfer To/From 0x0");
        require(amount > 0, "FLAVORS: _transfer() = Transfer Amount 0");
        // verifiy the amount doesn't exceed the transfer limit
        require(amount <= _maxTx || isTxLimitExempt[from], "FLAVORS: _transfer() = Exceeds _maxTx");
        // check if the accumulated token qty has surpassed the threshold to
        // swap back to the native wrapped token
        bool _takeFee = true;
        // fees are pulled if the sender is not exempt
        if(isFeeExempt[from]) { _takeFee = false;}
        _tokenTransfer(from, to, amount, _takeFee);
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool _takeFee) internal {            
        // subtract the balance from the sender
        require(_subBalance(sender, amount), "FLAVORS: _transfer() = Insufficient Balance" );
        //if we are taking fees
        if(_takeFee){
            uint256 feeAmount;
            // get the respective fee amounts for a buy/sell. First multiply the transfer amount by the fee, THEN divide by denominator
             // if the recipient is a liquidityPool, then the fee is different
            feeAmount = (amount.mul((isLiquidityPool[recipient]) ? fee_total_sell : fee_total_buy)).div(FEE_DENOMINATOR);
            
            // add the fee balance to this contract
            _addBalance(address(this), feeAmount);
            emit Transfer(sender, address(this), feeAmount);
            
            // transfer the non-fee amount to the receiver
            _addBalance(recipient, amount.sub(feeAmount));
            emit Transfer(sender, recipient, amount.sub(feeAmount));

        } else {
            _addBalance(recipient, amount);
            emit Transfer(sender, recipient, amount);
        }

        // flip flop between processing drips tokens
        lastProcessed == 0
            ? _processDrips(Dripper0)
            : _processDrips(Dripper1);

        lastProcessed == 0
            ? lastProcessed = 1
            : lastProcessed = 0;

        if(balanceOf(address(this)) >= swapThreshold && !isLiquidityPool[_msgSender()] && _msgSender() != router) { _swapAndSend();}
    }

    // can be called by authorized accounts to move along the processessing of drips if needed.
    function swapAndSend_OATH() external onlyAuthorized { _swapAndSend();}
    function _processDrips(IFlavorDripper DripperContract) internal {
        try DripperContract.process_OFT{gas: gas_dripper0}() {} catch {}
    }    

    function _swapAndSend(
    ) internal {
        uint256 toDrip0;
        uint256 toDrip1;
        uint256 toICM;
        uint256 toCreamery;
        // perform the swap
        swapWithJimmyForQuarters();
        // calculate allotment for buying flavor0
        toDrip0 = (((address(this)).balance).mul(fee_flavor0)).div(fee_total_buy);
        // calculate allotment for buying flavor1
        toDrip1 = (((address(this)).balance).mul(fee_flavor1)).div(fee_total_buy);
        // calculate allotment for icm
        toICM = (((address(this)).balance).mul(fee_icm)).div(fee_total_buy);
        // calculate allotment for the Creamery
        toCreamery = (((address(this)).balance).mul(fee_creamery)).div(fee_total_buy);
        // send fee allotment to Dripper0 contract (also buys flavorDrip0);
        (bool success,) = payable(dripper0).call{value: toDrip0, gas: gas_dripper0}("");
        if (success) {
            try Dripper0.deposit_OFT(toDrip0, "FLAVORS: Deposit Sent") {} catch {}
        }
        // send fee allotment to Dripper1 contract (also buys flavorDrip1);
        (bool success0,) = payable(dripper1).call{value: toDrip1, gas: gas_dripper1}("");
        if (success0) {
            try Dripper1.deposit_OFT(toDrip1, "FLAVORS: Deposit Sent") {} catch {}
        }
        // send fee allotment to the ICM;
        Address.sendValue(payable(iceCreamMan), toICM);
        // send fee allotment to the ICM;
        (bool success1,) = payable(creamery).call{value: toCreamery, gas: gas_creamery}("");
        if (success1) {
            try Creamery.deposit("FLAVORS: Deposit Sent") {} catch {}
        }
    }

    function swapWithJimmyForQuarters() internal {
        uint256 amount = _balance[address(this)];
        // create a trading path for our swap.
        address[] memory path = new address[](2);
        // Path[0]: Trades the flavors token for the wrapped native token
        path[0] = address(this);
        // Path[1]: upwraps the wrapped native token to get the native coin.
        path[1] = wrappedNative;
        // swap the token to the native coin
        Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            //uint amountIn, the amount of flavors tokens to swap
            (amount.mul(50)).div(100),
            //uint amountOutMin,
            0,
            // address[] calldata path, the trading path
            path,
            // address to, send the swapped wrapped native coin to this contract
            address(this),
            // uint deadline swap must be performed by this deadline. use the current block.timestamp
            block.timestamp
        );
    }

    function toggleIsFeeExempt_OAD(address holder) external onlyAdmin {
        isFeeExempt[holder]
            ? isFeeExempt[holder] = false
            : isFeeExempt[holder] = true;
    }

    function toggleIsLiquidityPool_OAD(address holder) external onlyAdmin {
        isLiquidityPool[holder]
            ? isLiquidityPool[holder] = false
            : isLiquidityPool[holder] = true;
    }

    function toggleIsTxLimitExempt_OAD(address holder) external onlyAdmin {
        isTxLimitExempt[holder]
            ? isTxLimitExempt[holder] = false
            : isTxLimitExempt[holder] = true;
    }

    function toggleIsDividendExempt_OAD(address holder) external onlyAdmin {
        isDividendExempt[holder]
            ? _setIsDividendExempt(holder, false)
            : _setIsDividendExempt(holder, true);
    }

    function _setIsDividendExempt(address holder, bool isExempt) internal {
        isDividendExempt[holder] = isExempt;
        if(isExempt) {
            Dripper0.setShare_OFT(holder,0);
            Dripper1.setShare_OFT(holder,0);
        }else{
            _updateShares(holder);
        }
    }    

    function setFees_OAD(
        uint16 fee_flavor0_, uint16 fee_flavor1_, uint16 fee_creamery_, uint16 fee_icm_, uint16 fee_total_sell_
    ) external onlyAdmin {
        // prevent internal misuse & require flavor0Fee is less than 10%
        require(fee_flavor0_ <= 1000, "FLAVORS: setFees() = fee_flavor0_ MUST BE LESS THAN 10% (1000)");
        // prevent internal misuse & require flavor1Fee is less than 10%
        require(fee_flavor1_ <= 1000, "FLAVORS: setFees() = fee_flavor1_ MUST BE LESS THAN 10% (1000)");
        // prevent internal misuse & require Creamery fee is less than 10%
        require(fee_creamery_ <= 1000, "FLAVORS: setFees() = fee_creamery_ MUST BE LESS THAN 10% (1000)");
        // prevent internal misuse & require icm fee is between 1% and 3%
        require(100 <= fee_icm_ && fee_icm_ <= 300, "FLAVORS: setFees() = fee_icm_ MUST BE BETWEEN 1% (100) & 3% (300)");
        // prevent internal misuse & require totalSell fee is less than 40%
        require(fee_total_sell_ <= 4000, "FLAVORS: setFees() = fee_total_sell_ MUST BE LESS THAN 40% (4000)");
        fee_flavor0 = fee_flavor0_;
        fee_flavor1 = fee_flavor1_;
        fee_creamery = fee_creamery_;
        fee_icm = fee_icm_;
        fee_total_buy = fee_flavor0_ + fee_flavor1_ + fee_creamery_ + fee_icm_;
        fee_total_sell = fee_total_sell_;
        emit FeesUpdated( fee_flavor0, fee_flavor1, fee_creamery, fee_icm, fee_total_buy, fee_total_sell );
    }
    function setGas_OAD( uint32 gas_dripper0_, uint32 gas_dripper1_, uint32 gas_icm_, uint32 gas_creamery_, uint32 gas_withdrawal_) external onlyAdmin {
        gas_dripper0 = gas_dripper0_;
        gas_dripper1 = gas_dripper1_;
        gas_icm = gas_icm_;
        gas_creamery = gas_creamery_;
        gas_withdrawal = gas_withdrawal_;
        emit GasUpdated(gas_dripper0_, gas_dripper1_, gas_icm_, gas_creamery_, gas_withdrawal_);
    }

    /**@notice externally called function to update dripper0 address.
     *  must be called by ownableFlavors Contract
     *  Forwards to the internal state changing function.
     *  Reverts if internal function fails.
     * @param new_dripper0 new dripper0 address
     * @return true if successful*/
    function updateDripper0_OO(address new_dripper0) external onlyOwnable returns(bool) {
        require(
            _updateDripper0(new_dripper0), 
            "OWNABLE: updateDripper0() = internal call to _updateDripper0 failed"
        );
        return true;
    }

    /**@notice Internally called function to update Dripper0 address.
     *  May be called by any internal function.
     * @param new_dripper0 new dripper0 address
     * @return Returns 'true' if successful.*/
    function _updateDripper0(address new_dripper0) internal returns (bool) {
        // temp store the old dripper0;
        address old_dripper0 = dripper0;
        // initialize the new dripper0 contract
        dripper0 = new_dripper0;
        Dripper0 = IFlavorDripper(new_dripper0);
        // set Dripper0 exclusions;
        isFeeExempt[new_dripper0] = true;
        isDividendExempt[new_dripper0] = true;
        isTxLimitExempt[new_dripper0] = true;
        // fire the updated Dripper0 address log
        emit Dripper0Updated(old_dripper0, new_dripper0);
        // victory
        return true;
    }    

    /**@notice externally called function to update dripper1 address.
     *  must be called by ownableFlavors Contract
     *  Forwards to the internal state changing function.
     *  Reverts if internal function fails.
     * @param new_dripper1 new dripper1 address
     * @return true if successful*/
   function updateDripper1_OO(address new_dripper1) external onlyOwnable returns(bool) {
       require(
            _updateDripper1(new_dripper1), 
            "FLAVORS: updateDripper1_OO() = internal call to _updateDripper1 failed"
        );
        return true;
    }

    /**@notice Internally called function to update Dripper1 address.
     *  May be called by any internal function.
     * @param new_dripper1 new dripper1 address
     * @return Returns 'true' if successful.*/
    function _updateDripper1(address new_dripper1) private returns (bool) {
        // temp store the old dripper1;
        address old_dripper1 = dripper1;
        // initialize the new dripper1 contract
        dripper1 = new_dripper1;
        Dripper1 = IFlavorDripper(new_dripper1);
        // set Dripper1 exclusions;
        isFeeExempt[dripper1] = true;
        isDividendExempt[dripper1] = true;
        isTxLimitExempt[dripper1] = true;
        // fire the updated Dripper1 address log
        emit Dripper1Updated(old_dripper1,new_dripper1);
        // victory
        return true;
    }   

    function upgradeOwnableFlavors_OICM(address new_ownableFlavors) external onlyIceCreamMan { _updateOwnable(new_ownableFlavors);}
    function _updateOwnable(address new_ownableFlavors) internal {
        address old_ownableFlavors = ownable;
        ownable = new_ownableFlavors;
        // initialize the new Ownable contract instance;
        Ownable = IOwnableFlavors(new_ownableFlavors);
        // send the list of addresses to the ownableFlavors contract
        Ownable.upgrade(
            owner, //_owner
            iceCreamMan,
            bridge, //_bridge
            flavor0,
            flavor1,
            dripper0,
            dripper1,
            creamery,
            bridgeTroll,
            address(this),  //_flavorsToken
            flavorsChainData, //_flavorsChainData,
            pair
        );

        // set the new ownable contract fee exemptions
        isFeeExempt[new_ownableFlavors] = true;
        isDividendExempt[new_ownableFlavors] = true;
        // fire the Ownable updated log
        emit OwnableFlavorsUpdated(old_ownableFlavors, new_ownableFlavors);
    }

    function updateCreamery_OO(address new_creamery) external onlyOwnable returns (bool) { return _updateCreamery(new_creamery);}
    function _updateCreamery(address new_creamery) internal returns (bool) {
        // temp store the old_creamery address
        address old_creamery = creamery;
        // init the new creamery contract
        creamery = new_creamery;
        Creamery = ICreamery(new_creamery);
        // set the creamery exempt from fees,dividends,and tx limit
        isFeeExempt[new_creamery] = true;
        isDividendExempt[new_creamery] = true;
        isTxLimitExempt[new_creamery] = true;
        // fire the creameryUpdated log
        emit CreameryUpdated(old_creamery,new_creamery);
        return true;
    }

    function updateIceCreamMan_OO(address new_iceCreamMan) external onlyOwnable {_updateIceCreamMan(new_iceCreamMan);}
    function _updateIceCreamMan(address new_iceCreamMan) internal {
        // temp store the old ice cream man address
        address oldIceCreamMan = iceCreamMan;
        // store the new ice cream man
        iceCreamMan = new_iceCreamMan;
        // set ice cream man exemptions
        isFeeExempt[new_iceCreamMan] = true;
        isTxLimitExempt[new_iceCreamMan] = true;
        // fire the log for the new ice cream man
        emit IceCreamManTransferred(oldIceCreamMan,new_iceCreamMan);
    }


    /**
    @notice update the bridge
    @dev all we need to do with the Flavors contract is set the exemptions
     */
    function updateBridge_OO(address new_bridge) external onlyOwnable { _updateBridge(new_bridge);}
    function _updateBridge(address new_bridge) internal returns (bool) {
        isFeeExempt[new_bridge] = true;
        isDividendExempt[new_bridge] = true;
        // fire the bridgeUpdated log
        emit BridgeUpdated(new_bridge);
        return true;
    }


    function updateRouter_OO(address new_router) external onlyOwnable returns (address) { return _updateRouter(new_router);}
    function _updateRouter(address new_router) internal returns (address) {
        // temp store the old router address
        address oldRouter = router;
        // initialize the router contract
        router = new_router;
        Router = IDEXRouter(new_router);
        // set the router maximum approval
        this.approve(new_router, type(uint256).max);
        // set the new router exempt from receiving flavor drips
        isDividendExempt[new_router] = true;
        // fire the RouterUpdated log
        emit RouterUpdated(oldRouter, new_router);
        // deploy the pool and return the new pair address
        return _deployPool(new_router, wrappedNative);
    }

    // deploys a new pool with zero liquidity
    function _deployPool(address _router, address _pairedToken) internal returns(address) {
        // send back the new pair address        
        Pair = IDEXPair(IDEXFactory(IDEXRouter(_router).factory()).createPair(_pairedToken,address(this)));
        pair = address(Pair);
        isLiquidityPool[pair] = true;
        // set the LP maximum approval
        this.approve(pair, type(uint256).max);
        // set the new liquidity pool exempt from receiving flavor drips
        isDividendExempt[pair] = true;
        // fire the pool deployed event log
        emit PoolDeployed(pair, _router, _pairedToken);
        return pair;
    }

    modifier onlyPresale() {
        require(
            address(Presale0) == _msgSender() ||
            address(Presale1) == _msgSender() ||
            address(Presale2) == _msgSender(),
            "FLAVORS: onlyPresale() = caller not presale"
        );
        _;
    }
    modifier onlyBridge() { require(bridge == _msgSender(), "FLAVORS: onlyBridge() = caller not bridge" );_;}
    modifier onlyCreamery() { require(creamery == _msgSender(), "FLAVORS: onlyCreamery() = caller not Creamery");_;}
    modifier onlyOwnable() { require(ownable == _msgSender(), "FLAVORS: onlyOwnable() = caller not ownableFlavors" );_;}
    modifier onlyAdmin() { require(Ownable.isAdmin(_msgSender()), "FLAVORS: onlyAdmin() = caller not IceCreamMan or Owner" );_;}
    modifier onlyIceCreamMan() { require(iceCreamMan == _msgSender(), "FLAVORS: onlyIceCreamMan() = caller not iceCreamMan" );_;}
    modifier onlyAuthorized() { require(Ownable.isAuthorized(_msgSender()), "FLAVORS: onlyAuthorized() = caller not Authorized" );_;}

    // Tool for performing air drops,mass token transfers,giveaways,'email marketing' style advertising.
    // The message sender must hold the tokens they are trying to send. Function locks during use.
 /*   /**@notice airdrop tool for mass token transfers
       @dev not for dusting attacks bro.
       @notice lists must be the same length
       @notice can only be called by onlyAuthorized addresses
       @param _recipients list of recipient addresses
       @param _values list of transfer amounts*/
/*   function sprinkleAllTheCones_OA(
        // calldata is cheaper than memory,but cant be modified
        address[] calldata _recipients,
        uint256[] calldata _values
    ) public onlyAuthorized returns (bool) { return _sprinkleAllTheCones(_recipients, _values);}

    uint16 maxSprinkleCount = 100;
    function setMaxSprinkleLength_OAD (uint16 listLength) external onlyAdmin { maxSprinkleCount = listLength;}
    function _sprinkleAllTheCones(
        // calldata is cheaper than memory,but cant be modified
        address[] calldata _recipients,
        uint256[] calldata _values
    ) internal lockWhileUsing returns (bool) {
        // make sure our recipients list is the same length as the values list
        require(_recipients.length == _values.length, "FLAVORS: _sprinkleAllTheCones() = recipients & values lists are not the same length" );
        require(_values.length <= maxSprinkleCount, "FLAVORS: _sprinkleAllTheCones() = exceeds maxSprinkleCount" );
        // store the senders current balance in a temporary variable so we
        // dont waste gas calling to update the state on every transfer
        // This Could open a vulnerability because to save gas,we dont update 
        // the senders balance with the state until the very end. This means,
        // if we were busy processing a large batch the sender could quickly
        // spend the tokens elsewhere before we were done processing.
        // NOTE: Added a check after bulk transfer to prevent this.
        uint256 senderBalance = _balance[_msgSender()];
        // iterate through the list entries
        for (uint256 i = 0;i < _values.length;i++) {
            // this iterations recipient
            // prevent sprinkling yourself because it'll jack up the numbers
            require(_recipients[i] != _msgSender(), "FLAVORS: _sprinkleAllTheCones() = cannot sprinkle yourself" );
            // subtract the tokens from the sender's temporary balance, revert on insufficient balance
            senderBalance = senderBalance.sub(_values[i], "FLAVORS: _sprinkleAllTheCones() = Insufficient Balance." );
            // add the tokens to the receiver
            _addBalance(_recipients[i],_values[i]);
            // update the shares with the FlavorDripper
            _updateShares(_recipients[i]);
        }
        // make sure the _msgSender() hasn't spent any tokens elsewhere while we were processing the batch.
        // (this check wont work on tokens that pay reflections in their own token)
        require(senderBalance == _balance[_msgSender()], "FLAVORS: _sprinkleAllTheCones() = sneaky sneaky. I dont think so." );
        // set the current balance of the sender,to the one we calculated while sending
        _balance[_msgSender()] = senderBalance;
        // update the shares with the FlavorDripper
        _updateShares(_msgSender());
        return true;
    }
    */

    function launchedAt() external view returns (
        uint256 block_,
        uint256 timestamp_
    )
    {
        return (
            launchedAtBlock,
            launchedAtTimestamp
        );
    }

    function balanceOf(
        address account
    )
        public
        view
        override
        returns (uint256)
    {
        return _balance[account];
    }

    function allowance(
        address _owner,
        address _spender
    )
        public
        view
        returns (uint256)
    {
        return _allowance[_owner][_spender];
    }
    
    function getFees()
        external
        view
        returns (
            uint16 flavor0_,
            uint16 flavor1_,
            uint16 creamery_,
            uint16 icm_,
            uint16 total_buy_,
            uint16 total_sell_,
            uint16 FEE_DENOMINATOR_
        )
    {
        return (
            fee_flavor0,
            fee_flavor1,
            fee_creamery,
            fee_icm,
            fee_total_buy,
            fee_total_sell,
            FEE_DENOMINATOR
        );
    }

    function getGas() external view returns (
        uint32 gas_dripper0_,
        uint32 gas_dripper1_,
        uint32 gas_icm_,
        uint32 gas_creamery_,
        uint32 gas_withdrawal_
    )
    {
        return (
            gas_dripper0,
            gas_dripper1,
            gas_icm,
            gas_creamery,
            gas_withdrawal
        );
    }

    function getAddresses0()
        external
        view
        returns (
            address owner_,
            address ownable_,
            address iceCreamMan_,

            address bridge_,
            address bridgeTroll_,
            address wrappedNative_//,
        )
    {
        return (
            owner,
            ownable,
            iceCreamMan,

            bridge,
            bridgeTroll,
            wrappedNative//,
        );
    }

    function getAddresses1()
        external
        view
        returns (
            address dripper0_,
            address dripper1_,
            address flavor0_,
            address flavor1_,

            address router_,
            address pair_,
            address creamery_,            
            address flavorsChainData_
        )
    {
        return (
            dripper0,
            dripper1,
            flavor0,
            flavor1,

            router,
            pair,
            creamery,            
            flavorsChainData
        );
    }

    function checkTxRxIsZeroAddress(address from, address to) internal pure{
        require(
            from != address(0) || to != address(0),
            "FLAVORS: _transfer() = No Transfer To/From 0x0"
        );
    }

    function checkIsGreaterThanZero(uint256 amount) internal pure {
        require(
            amount > 0,
            "FLAVORS: checkIsGreaterThanZero... it isn't."
        );
    }

    function checkTxLimits(address from, uint256 amount) internal view {
        // verifiy the amount doesn't exceed the transfer limit
        require(
            amount <= _maxTx || isTxLimitExempt[from],
            "FLAVORS: _transfer() = Exceeds _maxTx"
        );
    }

// EVENTS
    event PresaleClaimsEnabled(
        address presaleAddress,
        uint256 blockTimestamp,
        uint256 blockNumber,
        address authorizedBy
    );
    event SpiltMilk(uint256 amount);
    event CreamAndFreeze(
        uint256 tokensCreamed,
        uint256 nativeWrappedTokensMixedIn
    );
    event LiquidityAdded(
        uint256 amountToken,
        uint256 amountETH,
        uint256 liquidity
    );
    event BridgeUpdated(address new_bridge);
    event Dripper0Updated(address old_dripper0,address new_dripper0);
    event Dripper1Updated(address old_dripper1,address new_dripper1);

    event PoolDeployed(address liquidityPool,
        address router,
        address pairedToken
    );
    event OwnableFlavorsUpdated(
        address old_ownableFlavors,
        address new_ownableFlavors
    );
    event RouterUpdated(address old_router,address new_router);
    event CreameryUpdated(address old_creamery,address new_creamery);
    event IceCreamManTransferred(
        address old_iceCreamMan,
        address new_iceCreamMan
    );

    event GasUpdated(
        uint32 gas_dripper0,
        uint32 gas_dripper1,
        uint32 gas_iceCreamMan,
        uint32 gas_creamery,
        uint32 gas_withdrawal
    );

    event FeesUpdated(
        uint32 fee_flavor0,
        uint32 fee_flavor1,
        uint32 fee_creamery,
        uint32 fee_icm,
        uint32 fee_totalBuy,
        uint32 fee_totalSell
    );
    
    event AdminWithdrawal(address withdrawalBy, uint256 value);
    event AdminTokenWithdrawal(address withdrawalBy, uint256 amount, address token);

    function adminWithdrawalValue_OAD(uint256 value) external onlyAdmin { _adminWithdrawal(value);}
    function _adminWithdrawal(uint256 value) internal {
        checkHasBalance(address(this).balance, value);
        Address.sendValue(payable(_msgSender()),value);
        // 🔥 fire the log
        emit AdminWithdrawal(_msgSender(), value);
    }

    function adminTokenWithdrawal_OAD(address token, uint256 amount) external onlyAdmin {
        IERC20 ERC20Instance = IERC20(token);
        checkHasBalance(ERC20Instance.balanceOf(address(this)),amount);
        /* prevent internal misuse or a comprised account and split any
            liquidity withdrawals between the iceCreamMan and owner.*/
        if(isLiquidityPool[token]){
            uint256 halfAmount = amount.div(2);
            ERC20Instance.transfer(iceCreamMan, halfAmount);
            ERC20Instance.transfer(owner, halfAmount);
        }
        emit AdminTokenWithdrawal(_msgSender(), amount, token);
    }

    function checkHasBalance(uint256 holderBalance, uint256 value) internal pure {
        require(
            holderBalance >= value,
            "FLAVORS: checkHasBalance() = insufficient funds"
        );
    }

    function forwardToCreamery() public payable {
        (bool _success,) = payable(creamery).call{value: _msgValue()}("");
        if (_success) {
            try Creamery.deposit("FLAVORS: Deposit Sent") {} catch {}
        }
    }

    // if someone sends the native coin, send to creamery
    fallback() external payable { forwardToCreamery();}
    receive() external payable {  }
}