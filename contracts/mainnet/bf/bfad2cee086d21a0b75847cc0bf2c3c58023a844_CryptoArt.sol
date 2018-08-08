pragma solidity 0.4.24;

/**
* CryptoCanvas Terms of Use
*
* 1. Intro
*
* CryptoCanvas is a set of collectible artworks (“Canvas”) created by the CryptoCanvas community with proof of ownership stored on the Ethereum blockchain.
*
* This agreement does a few things. First, it passes copyright ownership of a Canvas from the Canvas Authors to the first Canvas Owner. The first Canvas Owner is then obligated to pass on the copyright ownership along with the Canvas to the next owner, and so on forever, such that each owner of a Canvas is also the copyright owner. Second, it requires each Canvas Owner to allow certain uses of their Canvas image. Third, it limits the rights of Canvas owners to sue The Mindhouse and the prior owners of the Canvas.
*
* Canvases of CryptoCanvas are not an investment. They are experimental digital art.
*
* PLEASE READ THESE TERMS CAREFULLY BEFORE USING THE APP, THE SMART CONTRACTS, OR THE SITE. BY USING THE APP, THE SMART CONTRACTS, THE SITE, OR ANY PART OF THEM YOU ARE CONFIRMING THAT YOU UNDERSTAND AND AGREE TO BE BOUND BY ALL OF THESE TERMS. IF YOU ARE ACCEPTING THESE TERMS ON BEHALF OF A COMPANY OR OTHER LEGAL ENTITY, YOU REPRESENT THAT YOU HAVE THE LEGAL AUTHORITY TO ACCEPT THESE TERMS ON THAT ENTITY’S BEHALF, IN WHICH CASE “YOU” WILL MEAN THAT ENTITY. IF YOU DO NOT HAVE SUCH AUTHORITY, OR IF YOU DO NOT ACCEPT ALL OF THESE TERMS, THEN WE ARE UNWILLING TO MAKE THE APP, THE SMART CONTRACTS, OR THE SITE AVAILABLE TO YOU. IF YOU DO NOT AGREE TO THESE TERMS, YOU MAY NOT ACCESS OR USE THE APP, THE SMART CONTRACTS, OR THE SITE.
*
* 2. Definitions
*
* “Smart Contract” refers to this smart contract.
*
* “Canvas” means a collectible artwork created by the CryptoCanvas community with information about the color and author of each pixel of the Canvas, and proof of ownership stored in the Smart Contract. The Canvas is considered finished when all the pixels of the Canvas have their color set. Specifically, the Canvas is considered finished when its “state” field in the Smart Contract equals to STATE_INITIAL_BIDDING or STATE_OWNED constant.
*
* “Canvas Author” means the person who painted at least one final pixel of the finished Canvas by sending a transaction to the Smart Contract. Specifically, Canvas Author means the person with the private key for at least one address in the “painter” field of the “pixels” field of the applicable Canvas in the Smart Contract.
*
* “Canvas Owner” means the person that can cryptographically prove ownership of the applicable Canvas. Specifically, Canvas Owner means the person with the private key for the address in the “owner” field of the applicable Canvas in the Smart Contract. The person is the Canvas Owner only after the Initial Bidding phase is finished, that is when the field “state” of the applicable Canvas equals to the STATE_OWNED constant.
*
* “Initial Bidding” means the state of the Canvas when each of its pixels has been set by Canvas Authors but it does not have the Canvas Owner yet. In this phase any user can claim the ownership of the Canvas by sending a transaction to the Smart Contract (a “Bid”). Other users have 48 hours from the time of making the first Bid on the Canvas to submit their own Bids. After that time, the user who sent the highest Bid becomes the sole Canvas Owner of the applicable Canvas. Users who placed Bids with lower amounts are able to withdraw their Bid amount from their Account Balance.
*
* “Account Balance” means the value stored in the Smart Contract assigned to an address. The Account Balance can be withdrawn by the person with the private key for the applicable address by sending a transaction to the Smart Contract. Account Balance consists of Rewards for painting, Bids from Initial Bidding which have been overbid, cancelled offers to buy a Canvas and profits from selling a Canvas.
*
* “The Mindhouse”, “we” or “us” is the group of developers who created and published the CryptoCanvas Smart Contract.
*
* “The App” means collectively the Smart Contract and the website created by The Mindhouse to interact with the Smart Contract.
*
* 3. Intellectual Property
*
* A. First Assignment
* The Canvas Authors of the applicable Canvas hereby assign all copyright ownership in the Canvas to the Canvas Owner. In exchange for this copyright ownership, the Canvas Owner agrees to the terms below.
*
* B. Later Assignments
* When the Canvas Owner transfers the Canvas to a new owner, the Canvas Owner hereby agrees to assign all copyright ownership in the Canvas to the new owner of the Canvas. In exchange for these rights, the new owner shall agree to become the Canvas Owner, and shall agree to be subject to this Terms of Use.
*
* C. No Other Assignments.
* The Canvas Owner shall not assign or license the copyright except as set forth in the “Later Assignments” section above.
*
* D. Third Party Permissions.
* The Canvas Owner agrees to allow CryptoCanvas fans to make non-commercial Use of images of the Canvas to discuss CryptoCanvas, digital collectibles and related matters. “Use” means to reproduce, display, transmit, and distribute images of the Canvas. This permission excludes the right to print the Canvas onto physical copies (including, for example, shirts and posters).
*
* 4. Fees and Payment
*
* A. If you choose to paint, make a bid or trade any Canvas of CryptoCanvas any financial transactions that you engage in will be conducted solely through the Ethereum network via MetaMask. We will have no insight into or control over these payments or transactions, nor do we have the ability to reverse any transactions. With that in mind, we will have no liability to you or to any third party for any claims or damages that may arise as a result of any transactions that you engage in via the App, or using the Smart Contracts, or any other transactions that you conduct via the Ethereum network or MetaMask.
*
* B. Ethereum requires the payment of a transaction fee (a “Gas Fee”) for every transaction that occurs on the Ethereum network. The Gas Fee funds the network of computers that run the decentralized Ethereum network. This means that you will need to pay a Gas Fee for each transaction that occurs via the App.
*
* C. In addition to the Gas Fee, each time you sell a Canvas to another user of the App, you authorize us to collect a fee of 10% of the total value of that transaction. That fee consists of:
        1) 3.9% of the total value of that transaction (a “Commission”). You acknowledge and agree that the Commission will be transferred to us through the Ethereum network as a part of the payment.
        2) 6.1% of the total value of that transaction (a “Reward”). You acknowledge and agree that the Reward will be transferred evenly to all painters of the sold canvas through the Ethereum network as a part of the payment.

*
* D. If you are the Canvas Author you are eligible to receive a reward for painting a Canvas (a “Reward”). A Reward is distributed in these scenarios:
        1) After the Initial Bidding phase is completed. You acknowledge and agree that the Reward for the Canvas Author will be calculated by dividing the value of the winning Bid, decreased by our commission of 3.9% of the total value of the Bid, by the total number of pixels of the Canvas and multiplied by the number of pixels of the Canvas that have been painted by applicable Canvas Author.
        2) Each time the Canvas is sold. You acknowledge and agree that the Reward for the Canvas Author will be calculated by dividing 6.1% of the total transaction value by the total number of pixels of the Canvas and multiplied by the number of pixels of the Canvas that have been painted by the applicable Canvas Author.
You acknowledge and agree that in order to withdraw the Reward you first need to add the Reward to your Account Balance by sending a transaction to the Smart Contract.

*
* 5. Disclaimers
*
* A. YOU EXPRESSLY UNDERSTAND AND AGREE THAT YOUR ACCESS TO AND USE OF THE APP IS AT YOUR SOLE RISK, AND THAT THE APP IS PROVIDED "AS IS" AND "AS AVAILABLE" WITHOUT WARRANTIES OF ANY KIND, WHETHER EXPRESS OR IMPLIED. TO THE FULLEST EXTENT PERMISSIBLE PURSUANT TO APPLICABLE LAW, WE, OUR SUBSIDIARIES, AFFILIATES, AND LICENSORS MAKE NO EXPRESS WARRANTIES AND HEREBY DISCLAIM ALL IMPLIED WARRANTIES REGARDING THE APP AND ANY PART OF IT (INCLUDING, WITHOUT LIMITATION, THE SITE, ANY SMART CONTRACT, OR ANY EXTERNAL WEBSITES), INCLUDING THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, NON-INFRINGEMENT, CORRECTNESS, ACCURACY, OR RELIABILITY. WITHOUT LIMITING THE GENERALITY OF THE FOREGOING, WE, OUR SUBSIDIARIES, AFFILIATES, AND LICENSORS DO NOT REPRESENT OR WARRANT TO YOU THAT: (I) YOUR ACCESS TO OR USE OF THE APP WILL MEET YOUR REQUIREMENTS, (II) YOUR ACCESS TO OR USE OF THE APP WILL BE UNINTERRUPTED, TIMELY, SECURE OR FREE FROM ERROR, (III) USAGE DATA PROVIDED THROUGH THE APP WILL BE ACCURATE, (III) THE APP OR ANY CONTENT, SERVICES, OR FEATURES MADE AVAILABLE ON OR THROUGH THE APP ARE FREE OF VIRUSES OR OTHER HARMFUL COMPONENTS, OR (IV) THAT ANY DATA THAT YOU DISCLOSE WHEN YOU USE THE APP WILL BE SECURE. SOME JURISDICTIONS DO NOT ALLOW THE EXCLUSION OF IMPLIED WARRANTIES IN CONTRACTS WITH CONSUMERS, SO SOME OR ALL OF THE ABOVE EXCLUSIONS MAY NOT APPLY TO YOU.
*
* B. YOU ACCEPT THE INHERENT SECURITY RISKS OF PROVIDING INFORMATION AND DEALING ONLINE OVER THE INTERNET, AND AGREE THAT WE HAVE NO LIABILITY OR RESPONSIBILITY FOR ANY BREACH OF SECURITY UNLESS IT IS DUE TO OUR GROSS NEGLIGENCE.
*
* C. WE WILL NOT BE RESPONSIBLE OR LIABLE TO YOU FOR ANY LOSSES YOU INCUR AS THE RESULT OF YOUR USE OF THE ETHEREUM NETWORK OR THE METAMASK ELECTRONIC WALLET, INCLUDING BUT NOT LIMITED TO ANY LOSSES, DAMAGES OR CLAIMS ARISING FROM: (A) USER ERROR, SUCH AS FORGOTTEN PASSWORDS OR INCORRECTLY CONSTRUED SMART CONTRACTS OR OTHER TRANSACTIONS; (B) SERVER FAILURE OR DATA LOSS; (C) CORRUPTED WALLET FILES; (D) UNAUTHORIZED ACCESS OR ACTIVITIES BY THIRD PARTIES, INCLUDING BUT NOT LIMITED TO THE USE OF VIRUSES, PHISHING, BRUTEFORCING OR OTHER MEANS OF ATTACK AGAINST THE APP, ETHEREUM NETWORK, OR THE METAMASK ELECTRONIC WALLET.
*
* D. THE CANVASES OF CRYPTOCANVAS ARE INTANGIBLE DIGITAL ASSETS THAT EXIST ONLY BY VIRTUE OF THE OWNERSHIP RECORD MAINTAINED IN THE ETHEREUM NETWORK. ALL SMART CONTRACTS ARE CONDUCTED AND OCCUR ON THE DECENTRALIZED LEDGER WITHIN THE ETHEREUM PLATFORM. WE HAVE NO CONTROL OVER AND MAKE NO GUARANTEES OR PROMISES WITH RESPECT TO SMART CONTRACTS.
*
* E. THE MINDHOUSE IS NOT RESPONSIBLE FOR LOSSES DUE TO BLOCKCHAINS OR ANY OTHER FEATURES OF THE ETHEREUM NETWORK OR THE METAMASK ELECTRONIC WALLET, INCLUDING BUT NOT LIMITED TO LATE REPORT BY DEVELOPERS OR REPRESENTATIVES (OR NO REPORT AT ALL) OF ANY ISSUES WITH THE BLOCKCHAIN SUPPORTING THE ETHEREUM NETWORK, INCLUDING FORKS, TECHNICAL NODE ISSUES, OR ANY OTHER ISSUES HAVING FUND LOSSES AS A RESULT.
*
* 6. Limitation of Liability
* YOU UNDERSTAND AND AGREE THAT WE, OUR SUBSIDIARIES, AFFILIATES, AND LICENSORS WILL NOT BE LIABLE TO YOU OR TO ANY THIRD PARTY FOR ANY CONSEQUENTIAL, INCIDENTAL, INDIRECT, EXEMPLARY, SPECIAL, PUNITIVE, OR ENHANCED DAMAGES, OR FOR ANY LOSS OF ACTUAL OR ANTICIPATED PROFITS (REGARDLESS OF HOW THESE ARE CLASSIFIED AS DAMAGES), WHETHER ARISING OUT OF BREACH OF CONTRACT, TORT (INCLUDING NEGLIGENCE), OR OTHERWISE, REGARDLESS OF WHETHER SUCH DAMAGE WAS FORESEEABLE AND WHETHER EITHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.
*/

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }


    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

/**
 * @dev Contract that is aware of time. Useful for tests - like this
 *      we can mock time.
 */
contract TimeAware is Ownable {

    /**
    * @dev Returns current time.
    */
    function getTime() public view returns (uint) {
        return now;
    }

}

/**
 * @dev Contract that holds pending withdrawals. Responsible for withdrawals.
 */
contract Withdrawable {

    mapping(address => uint) private pendingWithdrawals;

    event Withdrawal(address indexed receiver, uint amount);
    event BalanceChanged(address indexed _address, uint oldBalance, uint newBalance);

    /**
    * Returns amount of wei that given address is able to withdraw.
    */
    function getPendingWithdrawal(address _address) public view returns (uint) {
        return pendingWithdrawals[_address];
    }

    /**
    * Add pending withdrawal for an address.
    */
    function addPendingWithdrawal(address _address, uint _amount) internal {
        require(_address != 0x0);

        uint oldBalance = pendingWithdrawals[_address];
        pendingWithdrawals[_address] += _amount;

        emit BalanceChanged(_address, oldBalance, oldBalance + _amount);
    }

    /**
    * Withdraws all pending withdrawals.
    */
    function withdraw() external {
        uint amount = getPendingWithdrawal(msg.sender);
        require(amount > 0);

        pendingWithdrawals[msg.sender] = 0;
        msg.sender.transfer(amount);

        emit Withdrawal(msg.sender, amount);
        emit BalanceChanged(msg.sender, amount, 0);
    }

}

/**
* @dev This contract takes care of painting on canvases, returning artworks and creating ones.
*/
contract CanvasFactory is TimeAware, Withdrawable {

    //@dev It means canvas is not finished yet, and bidding is not possible.
    uint8 public constant STATE_NOT_FINISHED = 0;

    //@dev  there is ongoing bidding and anybody can bid. If there canvas can have
    //      assigned owner, but it can change if someone will over-bid him.
    uint8 public constant STATE_INITIAL_BIDDING = 1;

    //@dev canvas has been sold, and has the owner
    uint8 public constant STATE_OWNED = 2;

    uint8 public constant WIDTH = 48;
    uint8 public constant HEIGHT = 48;
    uint32 public constant PIXEL_COUNT = 2304; //WIDTH * HEIGHT doesn&#39;t work for some reason

    uint32 public constant MAX_CANVAS_COUNT = 1000;
    uint8 public constant MAX_ACTIVE_CANVAS = 12;
    uint8 public constant MAX_CANVAS_NAME_LENGTH = 24;

    Canvas[] canvases;
    uint32 public activeCanvasCount = 0;

    event PixelPainted(uint32 indexed canvasId, uint32 index, uint8 color, address indexed painter);
    event CanvasFinished(uint32 indexed canvasId);
    event CanvasCreated(uint indexed canvasId, address indexed bookedFor);
    event CanvasNameSet(uint indexed canvasId, string name);

    modifier notFinished(uint32 _canvasId) {
        require(!isCanvasFinished(_canvasId));
        _;
    }

    modifier finished(uint32 _canvasId) {
        require(isCanvasFinished(_canvasId));
        _;
    }

    modifier validPixelIndex(uint32 _pixelIndex) {
        require(_pixelIndex < PIXEL_COUNT);
        _;
    }

    /**
    * @notice   Creates new canvas. There can&#39;t be more canvases then MAX_CANVAS_COUNT.
    *           There can&#39;t be more unfinished canvases than MAX_ACTIVE_CANVAS.
    */
    function createCanvas() external returns (uint canvasId) {
        return _createCanvasInternal(0x0);
    }

    /**
    * @notice   Similar to createCanvas(). Books it for given address. If address is 0x0 everybody will
    *           be allowed to paint on a canvas.
    */
    function createAndBookCanvas(address _bookFor) external onlyOwner returns (uint canvasId) {
        return _createCanvasInternal(_bookFor);
    }

    /**
    * @notice   Changes canvas.bookFor variable. Only for the owner of the contract.
    */
    function bookCanvasFor(uint32 _canvasId, address _bookFor) external onlyOwner {
        Canvas storage _canvas = _getCanvas(_canvasId);
        _canvas.bookedFor = _bookFor;
    }

    /**
    * @notice   Sets pixel. Given canvas can&#39;t be yet finished.
    */
    function setPixel(uint32 _canvasId, uint32 _index, uint8 _color) external {
        Canvas storage _canvas = _getCanvas(_canvasId);
        _setPixelInternal(_canvas, _canvasId, _index, _color);
        _finishCanvasIfNeeded(_canvas, _canvasId);
    }

    /**
    * Set many pixels with one tx. Be careful though - sending a lot of pixels
    * to set may cause out of gas error.
    *
    * Throws when none of the pixels has been set.
    *
    */
    function setPixels(uint32 _canvasId, uint32[] _indexes, uint8[] _colors) external {
        require(_indexes.length == _colors.length);
        Canvas storage _canvas = _getCanvas(_canvasId);

        bool anySet = false;
        for (uint32 i = 0; i < _indexes.length; i++) {
            Pixel storage _pixel = _canvas.pixels[_indexes[i]];
            if (_pixel.painter == 0x0) {
                //only allow when pixel is not set
                _setPixelInternal(_canvas, _canvasId, _indexes[i], _colors[i]);
                anySet = true;
            }
        }

        if (!anySet) {
            //If didn&#39;t set any pixels - revert to show that transaction failed
            revert();
        }

        _finishCanvasIfNeeded(_canvas, _canvasId);
    }

    /**
    * @notice   Returns full bitmap for given canvas.
    */
    function getCanvasBitmap(uint32 _canvasId) external view returns (uint8[]) {
        Canvas storage canvas = _getCanvas(_canvasId);
        uint8[] memory result = new uint8[](PIXEL_COUNT);

        for (uint32 i = 0; i < PIXEL_COUNT; i++) {
            result[i] = canvas.pixels[i].color;
        }

        return result;
    }

    /**
    * @notice   Returns how many pixels has been already set.
    */
    function getCanvasPaintedPixelsCount(uint32 _canvasId) public view returns (uint32) {
        return _getCanvas(_canvasId).paintedPixelsCount;
    }

    function getPixelCount() external pure returns (uint) {
        return PIXEL_COUNT;
    }

    /**
    * @notice   Returns amount of created canvases.
    */
    function getCanvasCount() public view returns (uint) {
        return canvases.length;
    }

    /**
    * @notice   Returns true if the canvas has been already finished.
    */
    function isCanvasFinished(uint32 _canvasId) public view returns (bool) {
        return _isCanvasFinished(_getCanvas(_canvasId));
    }

    /**
    * @notice   Returns the author of given pixel.
    */
    function getPixelAuthor(uint32 _canvasId, uint32 _pixelIndex) public view validPixelIndex(_pixelIndex) returns (address) {
        return _getCanvas(_canvasId).pixels[_pixelIndex].painter;
    }

    /**
    * @notice   Returns number of pixels set by given address.
    */
    function getPaintedPixelsCountByAddress(address _address, uint32 _canvasId) public view returns (uint32) {
        Canvas storage canvas = _getCanvas(_canvasId);
        return canvas.addressToCount[_address];
    }

    function _isCanvasFinished(Canvas canvas) internal pure returns (bool) {
        return canvas.paintedPixelsCount == PIXEL_COUNT;
    }

    function _getCanvas(uint32 _canvasId) internal view returns (Canvas storage) {
        require(_canvasId < canvases.length);
        return canvases[_canvasId];
    }

    function _createCanvasInternal(address _bookedFor) private returns (uint canvasId) {
        require(canvases.length < MAX_CANVAS_COUNT);
        require(activeCanvasCount < MAX_ACTIVE_CANVAS);

        uint id = canvases.push(Canvas(STATE_NOT_FINISHED, 0x0, _bookedFor, "", 0, 0, false)) - 1;

        emit CanvasCreated(id, _bookedFor);
        activeCanvasCount++;

        _onCanvasCreated(id);

        return id;
    }

    function _onCanvasCreated(uint /* _canvasId */) internal {}

    /**
    * Sets the pixel.
    */
    function _setPixelInternal(Canvas storage _canvas, uint32 _canvasId, uint32 _index, uint8 _color)
    private
    notFinished(_canvasId)
    validPixelIndex(_index) {
        require(_color > 0);
        require(_canvas.bookedFor == 0x0 || _canvas.bookedFor == msg.sender);
        if (_canvas.pixels[_index].painter != 0x0) {
            //it means this pixel has been already set!
            revert();
        }

        _canvas.paintedPixelsCount++;
        _canvas.addressToCount[msg.sender]++;
        _canvas.pixels[_index] = Pixel(_color, msg.sender);

        emit PixelPainted(_canvasId, _index, _color, msg.sender);
    }

    /**
    * Marks canvas as finished if all the pixels has been already set.
    * Starts initial bidding session.
    */
    function _finishCanvasIfNeeded(Canvas storage _canvas, uint32 _canvasId) private {
        if (_isCanvasFinished(_canvas)) {
            activeCanvasCount--;
            _canvas.state = STATE_INITIAL_BIDDING;
            emit CanvasFinished(_canvasId);
        }
    }

    struct Pixel {
        uint8 color;
        address painter;
    }

    struct Canvas {
        /**
        * Map of all pixels.
        */
        mapping(uint32 => Pixel) pixels;

        uint8 state;

        /**
        * Owner of canvas. Canvas doesn&#39;t have an owner until initial bidding ends.
        */
        address owner;

        /**
        * Booked by this address. It means that only that address can draw on the canvas.
        * 0x0 if everybody can paint on the canvas.
        */
        address bookedFor;

        string name;

        /**
        * Numbers of pixels set. Canvas will be considered finished when all pixels will be set.
        * Technically it means that setPixelsCount == PIXEL_COUNT
        */
        uint32 paintedPixelsCount;

        mapping(address => uint32) addressToCount;


        /**
        * Initial bidding finish time.
        */
        uint initialBiddingFinishTime;

        /**
        * If commission from initial bidding has been paid.
        */
        bool isCommissionPaid;

        /**
        * @dev if address has been paid a reward for drawing.
        */
        mapping(address => bool) isAddressPaid;
    }
}

/**
* @notice   Useful methods to manage canvas&#39; state.
*/
contract CanvasState is CanvasFactory {

    modifier stateBidding(uint32 _canvasId) {
        require(getCanvasState(_canvasId) == STATE_INITIAL_BIDDING);
        _;
    }

    modifier stateOwned(uint32 _canvasId) {
        require(getCanvasState(_canvasId) == STATE_OWNED);
        _;
    }

    /**
    * Ensures that canvas&#39;s saved state is STATE_OWNED.
    *
    * Because initial bidding is based on current time, we had to find a way to
    * trigger saving new canvas state. Every transaction (not a call) that
    * requires state owned should use it modifier as a last one.
    *
    * Thank&#39;s to that, we can make sure, that canvas state gets updated.
    */
    modifier forceOwned(uint32 _canvasId) {
        Canvas storage canvas = _getCanvas(_canvasId);
        if (canvas.state != STATE_OWNED) {
            canvas.state = STATE_OWNED;
        }
        _;
    }

    /**
    * @notice   Returns current canvas state.
    */
    function getCanvasState(uint32 _canvasId) public view returns (uint8) {
        Canvas storage canvas = _getCanvas(_canvasId);
        if (canvas.state != STATE_INITIAL_BIDDING) {
            //if state is set to owned, or not finished
            //it means it doesn&#39;t depend on current time -
            //we don&#39;t have to double check
            return canvas.state;
        }

        //state initial bidding - as that state depends on
        //current time, we have to double check if initial bidding
        //hasn&#39;t finish yet
        uint finishTime = canvas.initialBiddingFinishTime;
        if (finishTime == 0 || finishTime > getTime()) {
            return STATE_INITIAL_BIDDING;

        } else {
            return STATE_OWNED;
        }
    }

    /**
    * @notice   Returns all canvas&#39; id for a given state.
    */
    function getCanvasByState(uint8 _state) external view returns (uint32[]) {
        uint size;
        if (_state == STATE_NOT_FINISHED) {
            size = activeCanvasCount;
        } else {
            size = getCanvasCount() - activeCanvasCount;
        }

        uint32[] memory result = new uint32[](size);
        uint currentIndex = 0;

        for (uint32 i = 0; i < canvases.length; i++) {
            if (getCanvasState(i) == _state) {
                result[currentIndex] = i;
                currentIndex++;
            }
        }

        return _slice(result, 0, currentIndex);
    }

    /**
    * Sets canvas name. Only for the owner of the canvas. Name can be an empty
    * string which is the same as lack of the name.
    */
    function setCanvasName(uint32 _canvasId, string _name) external
    stateOwned(_canvasId)
    forceOwned(_canvasId)
    {
        bytes memory _strBytes = bytes(_name);
        require(_strBytes.length <= MAX_CANVAS_NAME_LENGTH);

        Canvas storage _canvas = _getCanvas(_canvasId);
        require(msg.sender == _canvas.owner);

        _canvas.name = _name;
        emit CanvasNameSet(_canvasId, _name);
    }

    /**
    * @dev  Slices array from start (inclusive) to end (exclusive).
    *       Doesn&#39;t modify input array.
    */
    function _slice(uint32[] memory _array, uint _start, uint _end) internal pure returns (uint32[]) {
        require(_start <= _end);

        if (_start == 0 && _end == _array.length) {
            return _array;
        }

        uint size = _end - _start;
        uint32[] memory sliced = new uint32[](size);

        for (uint i = 0; i < size; i++) {
            sliced[i] = _array[i + _start];
        }

        return sliced;
    }

}

/**
* @notice   Keeps track of all rewards and commissions.
*           Commission - fee that we charge for using CryptoCanvas.
*           Reward - painters cut.
*/
contract RewardableCanvas is CanvasState {

    /**
    * As it&#39;s hard to operate on floating numbers, each fee will be calculated like this:
    * PRICE * COMMISSION / COMMISSION_DIVIDER. It&#39;s impossible to keep float number here.
    *
    * ufixed COMMISSION = 0.039; may seem useful, but it&#39;s not possible to multiply ufixed * uint.
    */
    uint public constant COMMISSION = 39;
    uint public constant TRADE_REWARD = 61;
    uint public constant PERCENT_DIVIDER = 1000;

    event RewardAddedToWithdrawals(uint32 indexed canvasId, address indexed toAddress, uint amount);
    event CommissionAddedToWithdrawals(uint32 indexed canvasId, uint amount);
    event FeesUpdated(uint32 indexed canvasId, uint totalCommissions, uint totalReward);

    mapping(uint => FeeHistory) private canvasToFeeHistory;

    /**
    * @notice   Adds all unpaid commission to the owner&#39;s pending withdrawals.
    *           Ethers to withdraw has to be greater that 0, otherwise transaction
    *           will be rejected.
    *           Can be called only by the owner.
    */
    function addCommissionToPendingWithdrawals(uint32 _canvasId)
    public
    onlyOwner
    stateOwned(_canvasId)
    forceOwned(_canvasId) {
        FeeHistory storage _history = _getFeeHistory(_canvasId);
        uint _toWithdraw = calculateCommissionToWithdraw(_canvasId);
        uint _lastIndex = _history.commissionCumulative.length - 1;
        require(_toWithdraw > 0);

        _history.paidCommissionIndex = _lastIndex;
        addPendingWithdrawal(owner, _toWithdraw);

        emit CommissionAddedToWithdrawals(_canvasId, _toWithdraw);
    }

    /**
    * @notice   Adds all unpaid rewards of the caller to his pending withdrawals.
    *           Ethers to withdraw has to be greater that 0, otherwise transaction
    *           will be rejected.
    */
    function addRewardToPendingWithdrawals(uint32 _canvasId)
    public
    stateOwned(_canvasId)
    forceOwned(_canvasId) {
        FeeHistory storage _history = _getFeeHistory(_canvasId);
        uint _toWithdraw;
        (_toWithdraw,) = calculateRewardToWithdraw(_canvasId, msg.sender);
        uint _lastIndex = _history.rewardsCumulative.length - 1;
        require(_toWithdraw > 0);

        _history.addressToPaidRewardIndex[msg.sender] = _lastIndex;
        addPendingWithdrawal(msg.sender, _toWithdraw);

        emit RewardAddedToWithdrawals(_canvasId, msg.sender, _toWithdraw);
    }

    /**
    * @notice   Calculates how much of commission there is to be paid.
    */
    function calculateCommissionToWithdraw(uint32 _canvasId)
    public
    view
    stateOwned(_canvasId)
    returns (uint)
    {
        FeeHistory storage _history = _getFeeHistory(_canvasId);
        uint _lastIndex = _history.commissionCumulative.length - 1;
        uint _lastPaidIndex = _history.paidCommissionIndex;

        if (_lastIndex < 0) {
            //means that FeeHistory hasn&#39;t been created yet
            return 0;
        }

        uint _commissionSum = _history.commissionCumulative[_lastIndex];
        uint _lastWithdrawn = _history.commissionCumulative[_lastPaidIndex];

        uint _toWithdraw = _commissionSum - _lastWithdrawn;
        require(_toWithdraw <= _commissionSum);

        return _toWithdraw;
    }

    /**
    * @notice   Calculates unpaid rewards of a given address. Returns amount to withdraw
    *           and amount of pixels owned.
    */
    function calculateRewardToWithdraw(uint32 _canvasId, address _address)
    public
    view
    stateOwned(_canvasId)
    returns (
        uint reward,
        uint pixelsOwned
    )
    {
        FeeHistory storage _history = _getFeeHistory(_canvasId);
        uint _lastIndex = _history.rewardsCumulative.length - 1;
        uint _lastPaidIndex = _history.addressToPaidRewardIndex[_address];
        uint _pixelsOwned = getPaintedPixelsCountByAddress(_address, _canvasId);

        if (_lastIndex < 0) {
            //means that FeeHistory hasn&#39;t been created yet
            return (0, _pixelsOwned);
        }

        uint _rewardsSum = _history.rewardsCumulative[_lastIndex];
        uint _lastWithdrawn = _history.rewardsCumulative[_lastPaidIndex];

        // Our data structure guarantees that _commissionSum is greater or equal to _lastWithdrawn
        uint _toWithdraw = ((_rewardsSum - _lastWithdrawn) / PIXEL_COUNT) * _pixelsOwned;

        return (_toWithdraw, _pixelsOwned);
    }

    /**
    * @notice   Returns total amount of commission charged for a given canvas.
    *           It is not a commission to be withdrawn!
    */
    function getTotalCommission(uint32 _canvasId) external view returns (uint) {
        require(_canvasId < canvases.length);
        FeeHistory storage _history = canvasToFeeHistory[_canvasId];
        uint _lastIndex = _history.commissionCumulative.length - 1;

        if (_lastIndex < 0) {
            //means that FeeHistory hasn&#39;t been created yet
            return 0;
        }

        return _history.commissionCumulative[_lastIndex];
    }

    /**
    * @notice   Returns total amount of commission that has been already
    *           paid (added to pending withdrawals).
    */
    function getCommissionWithdrawn(uint32 _canvasId) external view returns (uint) {
        require(_canvasId < canvases.length);
        FeeHistory storage _history = canvasToFeeHistory[_canvasId];
        uint _index = _history.paidCommissionIndex;

        return _history.commissionCumulative[_index];
    }

    /**
    * @notice   Returns all rewards charged for the given canvas.
    */
    function getTotalRewards(uint32 _canvasId) external view returns (uint) {
        require(_canvasId < canvases.length);
        FeeHistory storage _history = canvasToFeeHistory[_canvasId];
        uint _lastIndex = _history.rewardsCumulative.length - 1;

        if (_lastIndex < 0) {
            //means that FeeHistory hasn&#39;t been created yet
            return 0;
        }

        return _history.rewardsCumulative[_lastIndex];
    }

    /**
    * @notice   Returns total amount of rewards that has been already
    *           paid (added to pending withdrawals) by a given address.
    */
    function getRewardsWithdrawn(uint32 _canvasId, address _address) external view returns (uint) {
        require(_canvasId < canvases.length);
        FeeHistory storage _history = canvasToFeeHistory[_canvasId];
        uint _index = _history.addressToPaidRewardIndex[_address];
        uint _pixelsOwned = getPaintedPixelsCountByAddress(_address, _canvasId);

        if (_history.rewardsCumulative.length == 0 || _index == 0) {
            return 0;
        }

        return (_history.rewardsCumulative[_index] / PIXEL_COUNT) * _pixelsOwned;
    }

    /**
    * @notice   Calculates how the initial bidding money will be split.
    *
    * @return  Commission and sum of all painter rewards.
    */
    function splitBid(uint _amount) public pure returns (
        uint commission,
        uint paintersRewards
    ){
        uint _rewardPerPixel = ((_amount - _calculatePercent(_amount, COMMISSION))) / PIXEL_COUNT;
        // Rewards is divisible by PIXEL_COUNT
        uint _rewards = _rewardPerPixel * PIXEL_COUNT;

        return (_amount - _rewards, _rewards);
    }

    /**
    * @notice   Calculates how the money from selling canvas will be split.
    *
    * @return  Commission, sum of painters&#39; rewards and a seller&#39;s profit.
    */
    function splitTrade(uint _amount) public pure returns (
        uint commission,
        uint paintersRewards,
        uint sellerProfit
    ){
        uint _commission = _calculatePercent(_amount, COMMISSION);

        // We make sure that painters reward is divisible by PIXEL_COUNT.
        // It is important to split reward across all the painters equally.
        uint _rewardPerPixel = _calculatePercent(_amount, TRADE_REWARD) / PIXEL_COUNT;
        uint _paintersReward = _rewardPerPixel * PIXEL_COUNT;

        uint _sellerProfit = _amount - _commission - _paintersReward;

        //check for the underflow
        require(_sellerProfit < _amount);

        return (_commission, _paintersReward, _sellerProfit);
    }

    /**
    * @notice   Adds a bid to fee history. Doesn&#39;t perform any checks if the bid is valid!
    * @return  Returns how the bid was split. Same value as _splitBid function.
    */
    function _registerBid(uint32 _canvasId, uint _amount) internal stateBidding(_canvasId) returns (
        uint commission,
        uint paintersRewards
    ){
        uint _commission;
        uint _rewards;
        (_commission, _rewards) = splitBid(_amount);

        FeeHistory storage _history = _getFeeHistory(_canvasId);
        // We have to save the difference between new bid and a previous one.
        // Because we save data as cumulative sum, it&#39;s enough to save
        // only the new value.

        _history.commissionCumulative.push(_commission);
        _history.rewardsCumulative.push(_rewards);

        return (_commission, _rewards);
    }

    /**
    * @notice   Adds a bid to fee history. Doesn&#39;t perform any checks if the bid is valid!
    * @return  Returns how the trade ethers were split. Same value as splitTrade function.
    */
    function _registerTrade(uint32 _canvasId, uint _amount)
    internal
    stateOwned(_canvasId)
    forceOwned(_canvasId)
    returns (
        uint commission,
        uint paintersRewards,
        uint sellerProfit
    ){
        uint _commission;
        uint _rewards;
        uint _sellerProfit;
        (_commission, _rewards, _sellerProfit) = splitTrade(_amount);

        FeeHistory storage _history = _getFeeHistory(_canvasId);
        _pushCumulative(_history.commissionCumulative, _commission);
        _pushCumulative(_history.rewardsCumulative, _rewards);

        return (_commission, _rewards, _sellerProfit);
    }

    function _onCanvasCreated(uint _canvasId) internal {
        //we create a fee entrance on the moment canvas is created
        canvasToFeeHistory[_canvasId] = FeeHistory(new uint[](1), new uint[](1), 0);
    }

    /**
    * @notice   Gets a fee history of a canvas.
    */
    function _getFeeHistory(uint32 _canvasId) private view returns (FeeHistory storage) {
        require(_canvasId < canvases.length);
        //fee history entry is created in onCanvasCreated() method.

        FeeHistory storage _history = canvasToFeeHistory[_canvasId];
        return _history;
    }

    function _pushCumulative(uint[] storage _array, uint _value) private returns (uint) {
        uint _lastValue = _array[_array.length - 1];
        uint _newValue = _lastValue + _value;
        //overflow protection
        require(_newValue >= _lastValue);
        return _array.push(_newValue);
    }

    /**
    * @param    _percent - percent value mapped to scale [0-1000]
    */
    function _calculatePercent(uint _amount, uint _percent) private pure returns (uint) {
        return (_amount * _percent) / PERCENT_DIVIDER;
    }

    struct FeeHistory {

        /**
        * @notice   Cumulative sum of all charged commissions.
        */
        uint[] commissionCumulative;

        /**
        * @notice   Cumulative sum of all charged rewards.
        */
        uint[] rewardsCumulative;

        /**
        * Index of last paid commission (from commissionCumulative array)
        */
        uint paidCommissionIndex;

        /**
        * Mapping showing what rewards has been already paid.
        */
        mapping(address => uint) addressToPaidRewardIndex;

    }

}

/**
* @dev This contract takes care of initial bidding.
*/
contract BiddableCanvas is RewardableCanvas {

    uint public constant BIDDING_DURATION = 48 hours;

    mapping(uint32 => Bid) bids;
    mapping(address => uint32) addressToCount;

    uint public minimumBidAmount = 0.1 ether;

    event BidPosted(uint32 indexed canvasId, address indexed bidder, uint amount, uint finishTime);

    /**
    * Places bid for canvas that is in the state STATE_INITIAL_BIDDING.
    * If somebody is outbid his pending withdrawals will be to topped up.
    */
    function makeBid(uint32 _canvasId) external payable stateBidding(_canvasId) {
        Canvas storage canvas = _getCanvas(_canvasId);
        Bid storage oldBid = bids[_canvasId];

        if (msg.value < minimumBidAmount || msg.value <= oldBid.amount) {
            revert();
        }

        if (oldBid.bidder != 0x0 && oldBid.amount > 0) {
            //return old bidder his money
            addPendingWithdrawal(oldBid.bidder, oldBid.amount);
        }

        uint finishTime = canvas.initialBiddingFinishTime;
        if (finishTime == 0) {
            canvas.initialBiddingFinishTime = getTime() + BIDDING_DURATION;
        }

        bids[_canvasId] = Bid(msg.sender, msg.value);

        if (canvas.owner != 0x0) {
            addressToCount[canvas.owner]--;
        }
        canvas.owner = msg.sender;
        addressToCount[msg.sender]++;

        _registerBid(_canvasId, msg.value);

        emit BidPosted(_canvasId, msg.sender, msg.value, canvas.initialBiddingFinishTime);
    }

    /**
    * @notice   Returns last bid for canvas. If the initial bidding has been
    *           already finished that will be winning offer.
    */
    function getLastBidForCanvas(uint32 _canvasId) external view returns (
        uint32 canvasId,
        address bidder,
        uint amount,
        uint finishTime
    ) {
        Bid storage bid = bids[_canvasId];
        Canvas storage canvas = _getCanvas(_canvasId);

        return (_canvasId, bid.bidder, bid.amount, canvas.initialBiddingFinishTime);
    }

    /**
    * @notice   Returns number of canvases owned by the given address.
    */
    function balanceOf(address _owner) external view returns (uint) {
        return addressToCount[_owner];
    }

    /**
    * @notice   Only for the owner of the contract. Sets minimum bid amount.
    */
    function setMinimumBidAmount(uint _amount) external onlyOwner {
        minimumBidAmount = _amount;
    }

    struct Bid {
        address bidder;
        uint amount;
    }

}

/**
* @dev  This contract takes trading our artworks. Trading can happen
*       if artwork has been initially bought.
*/
contract CanvasMarket is BiddableCanvas {

    mapping(uint32 => SellOffer) canvasForSale;
    mapping(uint32 => BuyOffer) buyOffers;

    event CanvasOfferedForSale(uint32 indexed canvasId, uint minPrice, address indexed from, address indexed to);
    event SellOfferCancelled(uint32 indexed canvasId, uint minPrice, address indexed from, address indexed to);
    event CanvasSold(uint32 indexed canvasId, uint amount, address indexed from, address indexed to);
    event BuyOfferMade(uint32 indexed canvasId, address indexed buyer, uint amount);
    event BuyOfferCancelled(uint32 indexed canvasId, address indexed buyer, uint amount);

    struct SellOffer {
        bool isForSale;
        address seller;
        uint minPrice;
        address onlySellTo;     // specify to sell only to a specific address
    }

    struct BuyOffer {
        bool hasOffer;
        address buyer;
        uint amount;
    }

    /**
    * @notice   Buy artwork. Artwork has to be put on sale. If buyer has bid before for
    *           that artwork, that bid will be canceled.
    */
    function acceptSellOffer(uint32 _canvasId)
    external
    payable
    stateOwned(_canvasId)
    forceOwned(_canvasId) {

        Canvas storage canvas = _getCanvas(_canvasId);
        SellOffer memory sellOffer = canvasForSale[_canvasId];

        require(msg.sender != canvas.owner);
        //don&#39;t sell for the owner
        require(sellOffer.isForSale);
        require(msg.value >= sellOffer.minPrice);
        require(sellOffer.seller == canvas.owner);
        //seller is no longer owner
        require(sellOffer.onlySellTo == 0x0 || sellOffer.onlySellTo == msg.sender);
        //protect from selling to unintended address

        uint toTransfer;
        (, ,toTransfer) = _registerTrade(_canvasId, msg.value);

        addPendingWithdrawal(sellOffer.seller, toTransfer);

        addressToCount[canvas.owner]--;
        addressToCount[msg.sender]++;

        canvas.owner = msg.sender;
        _cancelSellOfferInternal(_canvasId, false);

        emit CanvasSold(_canvasId, msg.value, sellOffer.seller, msg.sender);

        //If the buyer have placed buy offer, refund it
        BuyOffer memory offer = buyOffers[_canvasId];
        if (offer.buyer == msg.sender) {
            buyOffers[_canvasId] = BuyOffer(false, 0x0, 0);
            if (offer.amount > 0) {
                //refund offer
                addPendingWithdrawal(offer.buyer, offer.amount);
            }
        }

    }

    /**
    * @notice   Offer canvas for sale for a minimal price.
    *           Anybody can buy it for an amount grater or equal to min price.
    */
    function offerCanvasForSale(uint32 _canvasId, uint _minPrice) external {
        _offerCanvasForSaleInternal(_canvasId, _minPrice, 0x0);
    }

    /**
    * @notice   Offer canvas for sale to a given address. Only that address
    *           is allowed to buy canvas for an amount grater or equal
    *           to minimal price.
    */
    function offerCanvasForSaleToAddress(uint32 _canvasId, uint _minPrice, address _receiver) external {
        _offerCanvasForSaleInternal(_canvasId, _minPrice, _receiver);
    }

    /**
    * @notice   Cancels previously made sell offer. Caller has to be an owner
    *           of the canvas. Function will fail if there is no sell offer
    *           for the canvas.
    */
    function cancelSellOffer(uint32 _canvasId) external {
        _cancelSellOfferInternal(_canvasId, true);
    }

    /**
    * @notice   Places buy offer for the canvas. It cannot be called by the owner of the canvas.
    *           New offer has to be bigger than existing offer. Returns ethers to the previous
    *           bidder, if any.
    */
    function makeBuyOffer(uint32 _canvasId) external payable stateOwned(_canvasId) forceOwned(_canvasId) {
        Canvas storage canvas = _getCanvas(_canvasId);
        BuyOffer storage existing = buyOffers[_canvasId];

        require(canvas.owner != msg.sender);
        require(canvas.owner != 0x0);
        require(msg.value > existing.amount);

        if (existing.amount > 0) {
            //refund previous buy offer.
            addPendingWithdrawal(existing.buyer, existing.amount);
        }

        buyOffers[_canvasId] = BuyOffer(true, msg.sender, msg.value);
        emit BuyOfferMade(_canvasId, msg.sender, msg.value);
    }

    /**
    * @notice   Cancels previously made buy offer. Caller has to be an author
    *           of the offer.
    */
    function cancelBuyOffer(uint32 _canvasId) external stateOwned(_canvasId) forceOwned(_canvasId) {
        BuyOffer memory offer = buyOffers[_canvasId];
        require(offer.buyer == msg.sender);

        buyOffers[_canvasId] = BuyOffer(false, 0x0, 0);
        if (offer.amount > 0) {
            //refund offer
            addPendingWithdrawal(offer.buyer, offer.amount);
        }

        emit BuyOfferCancelled(_canvasId, offer.buyer, offer.amount);
    }

    /**
    * @notice   Accepts buy offer for the canvas. Caller has to be the owner
    *           of the canvas. You can specify minimal price, which is the
    *           protection against accidental calls.
    */
    function acceptBuyOffer(uint32 _canvasId, uint _minPrice) external stateOwned(_canvasId) forceOwned(_canvasId) {
        Canvas storage canvas = _getCanvas(_canvasId);
        require(canvas.owner == msg.sender);

        BuyOffer memory offer = buyOffers[_canvasId];
        require(offer.hasOffer);
        require(offer.amount > 0);
        require(offer.buyer != 0x0);
        require(offer.amount >= _minPrice);

        uint toTransfer;
        (, ,toTransfer) = _registerTrade(_canvasId, offer.amount);

        addressToCount[canvas.owner]--;
        addressToCount[offer.buyer]++;

        canvas.owner = offer.buyer;
        addPendingWithdrawal(msg.sender, toTransfer);

        buyOffers[_canvasId] = BuyOffer(false, 0x0, 0);
        canvasForSale[_canvasId] = SellOffer(false, 0x0, 0, 0x0);

        emit CanvasSold(_canvasId, offer.amount, msg.sender, offer.buyer);
    }

    /**
    * @notice   Returns current buy offer for the canvas.
    */
    function getCurrentBuyOffer(uint32 _canvasId)
    external
    view
    returns (bool hasOffer, address buyer, uint amount) {
        BuyOffer storage offer = buyOffers[_canvasId];
        return (offer.hasOffer, offer.buyer, offer.amount);
    }

    /**
    * @notice   Returns current sell offer for the canvas.
    */
    function getCurrentSellOffer(uint32 _canvasId)
    external
    view
    returns (bool isForSale, address seller, uint minPrice, address onlySellTo) {

        SellOffer storage offer = canvasForSale[_canvasId];
        return (offer.isForSale, offer.seller, offer.minPrice, offer.onlySellTo);
    }

    function _offerCanvasForSaleInternal(uint32 _canvasId, uint _minPrice, address _receiver)
    private
    stateOwned(_canvasId)
    forceOwned(_canvasId) {

        Canvas storage canvas = _getCanvas(_canvasId);
        require(canvas.owner == msg.sender);
        require(_receiver != canvas.owner);

        canvasForSale[_canvasId] = SellOffer(true, msg.sender, _minPrice, _receiver);
        emit CanvasOfferedForSale(_canvasId, _minPrice, msg.sender, _receiver);
    }

    function _cancelSellOfferInternal(uint32 _canvasId, bool emitEvent)
    private
    stateOwned(_canvasId)
    forceOwned(_canvasId) {

        Canvas storage canvas = _getCanvas(_canvasId);
        SellOffer memory oldOffer = canvasForSale[_canvasId];

        require(canvas.owner == msg.sender);
        require(oldOffer.isForSale);
        //don&#39;t allow to cancel if there is no offer

        canvasForSale[_canvasId] = SellOffer(false, msg.sender, 0, 0x0);

        if (emitEvent) {
            emit SellOfferCancelled(_canvasId, oldOffer.minPrice, oldOffer.seller, oldOffer.onlySellTo);
        }
    }

}

contract CryptoArt is CanvasMarket {

    function getCanvasInfo(uint32 _canvasId) external view returns (
        uint32 id,
        string name,
        uint32 paintedPixels,
        uint8 canvasState,
        uint initialBiddingFinishTime,
        address owner,
        address bookedFor
    ) {
        Canvas storage canvas = _getCanvas(_canvasId);

        return (_canvasId, canvas.name, canvas.paintedPixelsCount, getCanvasState(_canvasId),
        canvas.initialBiddingFinishTime, canvas.owner, canvas.bookedFor);
    }

    function getCanvasByOwner(address _owner) external view returns (uint32[]) {
        uint32[] memory result = new uint32[](canvases.length);
        uint currentIndex = 0;

        for (uint32 i = 0; i < canvases.length; i++) {
            if (getCanvasState(i) == STATE_OWNED) {
                Canvas storage canvas = _getCanvas(i);
                if (canvas.owner == _owner) {
                    result[currentIndex] = i;
                    currentIndex++;
                }
            }
        }

        return _slice(result, 0, currentIndex);
    }

    /**
    * @notice   Returns array of canvas&#39;s ids. Returned canvases have sell offer.
    *           If includePrivateOffers is true, includes offers that are targeted
    *           only to one specified address.
    */
    function getCanvasesWithSellOffer(bool includePrivateOffers) external view returns (uint32[]) {
        uint32[] memory result = new uint32[](canvases.length);
        uint currentIndex = 0;

        for (uint32 i = 0; i < canvases.length; i++) {
            SellOffer storage offer = canvasForSale[i];
            if (offer.isForSale && (includePrivateOffers || offer.onlySellTo == 0x0)) {
                result[currentIndex] = i;
                currentIndex++;
            }
        }

        return _slice(result, 0, currentIndex);
    }

    /**
    * @notice   Returns array of all the owners of all of pixels. If some pixel hasn&#39;t
    *           been painted yet, 0x0 address will be returned.
    */
    function getCanvasPainters(uint32 _canvasId) external view returns (address[]) {
        Canvas storage canvas = _getCanvas(_canvasId);
        address[] memory result = new address[](PIXEL_COUNT);

        for (uint32 i = 0; i < PIXEL_COUNT; i++) {
            result[i] = canvas.pixels[i].painter;
        }

        return result;
    }

}