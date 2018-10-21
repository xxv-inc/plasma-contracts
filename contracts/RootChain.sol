pragma solidity ^0.4.0;

contract ERC20 {
  function transferFrom(address from, address to, uint256 value) public returns (bool) { return true; }
  function transfer(address to, uint256 value) public returns (bool) { return true; }
}

contract PriorityQueue {
    /*
     * This is an naive implementation of a bounded size priority queue.
     * Until we develop priority queue encodings at the solver level, this
     * can serve as a WIP placeholder to evaluate queue use in the Rootchain
     */

    uint256 public currentSize;

    uint256 POS_INF = 999999;
    uint256 N = 2;
    mapping(uint256 => uint256) highBits;
    mapping(uint256 => uint256) lowBits;
    mapping(uint256 => uint256) hasValue;

    function PriorityQueue() {
      currentSize = 0;
      uint256 i = 0;
      while (i < N) {
        hasValue[i] = 0;
        i = i + 1;
      }
    }

    function GETMIN_ON_EMPTY() private {
      assert(false);
    }

    function INSERT_WHEN_FULL() private {
      assert(false);
    }

    function getOpenIndex() returns (uint256) {
      uint256 i = 0;
      while (i < N) {
        if (hasValue[i] == 0)
          return i;
        i = i + 1;
      }
      INSERT_WHEN_FULL();
      return 0;
    }

    function getMinIndex() returns (uint256) {
      if (currentSize == 0) {
        GETMIN_ON_EMPTY();
        revert();
      }

      uint256 minIdx = POS_INF;
      uint256 minHighBits = POS_INF;
      uint256 minLowBits = POS_INF;
      uint256 i = 0;
      while (i < N) {
        if (hasValue[i] == 1) {
          if (highBits[i] < minHighBits || (highBits[i] == minHighBits && lowBits[i] < minLowBits)) {
            minHighBits = highBits[i];
            minLowBits = lowBits[i];
            minIdx = i;
          }
        }
        i = i + 1;
      }

      return minIdx;
    }

    function delMin() public returns (uint256) {
      uint256 idx = getMinIndex();
      hasValue[idx] = 0;
      currentSize = currentSize - 1;
      return currentSize;
    }

    function getMinHighBits() public view returns (uint256) {
      uint256 idx = getMinIndex();
      return highBits[idx];
    }

    function getMinLowBits() public view returns (uint256) {
      uint256 idx = getMinIndex();
      return lowBits[idx];
    }

    function insert(uint256 high, uint256 low) public {
      uint256 idx = getOpenIndex();
      hasValue[idx] = 1;
      currentSize = currentSize + 1;
      lowBits[idx] = low;
      highBits[idx] = high;
    }
}

contract Exit {
    address public owner;
    address public token;
    uint256 public amount;

    function Exit(address o, address t, uint256 a) {
        owner = o;
        token = t;
        amount = a;
    }

    function delOwner() {
        delete owner;
    }
}

contract ChildBlock {
    bytes32 public root;
    uint256 public timestamp;

    function ChildBlock(bytes32 r, uint256 t) {
        root = r;
        timestamp = t;
    }
}


/**
 * @title RootChain
 * @dev This contract secures a utxo payments plasma child chain to ethereum.
 */
contract RootChain {
    /*
     * Events
     */

    event Deposit(
        address indexed depositor,
        uint256 indexed depositBlock,
        address token,
        uint256 amount
    );

    event ExitStarted(
        address indexed exitor,
        uint256 indexed utxoPos,
        address token,
        uint256 amount
    );

    event BlockSubmitted(
        uint256 blockNumber
    );

    event TokenAdded(
        address token
    );


    /*
     * Storage
     */

    uint256 public constant CHILD_BLOCK_INTERVAL = 1000;
    uint256 constant UTXO_POS_BLKSIZE = 1000000000;
    uint256 constant UTXO_POS_TXINDEX = 10000;

    address public operator;

    uint256 public currentChildBlock;
    uint256 public currentDepositBlock;
    uint256 public currentFeeExit;
    bytes placeholder;

    mapping (uint256 => address) public childChain;
    mapping (uint256 => address) public exits;
    mapping (address => address) public exitsQueues;

    /*
     * Modifiers
     */

    modifier onlyOperator() {
        require(msg.sender == operator);
        _;
    }


    /*
     * Constructor
     */

    function RootChain()
        public
    {
        operator = msg.sender;
        currentChildBlock = CHILD_BLOCK_INTERVAL;
        currentDepositBlock = 1;
        currentFeeExit = 1;
        // Support only ETH on deployment; other tokens need
        // to be added explicitly.
        exitsQueues[address(0)] = address(new PriorityQueue());
    }

    /*
     * Function from ByteUtils, Validate, Merklei, PlasmaRLP, ECRecovery inlined.
     * WIP: for testing SM infrastructure.
     * At the moment we abstract away their true functionality and return
     * trivial values. In final version, their actual functionality will be verified
     */

    function slice(bytes _bytes, uint _start, uint _length) public returns
    (bytes) { return _bytes; }

    function checkSigs(bytes32 txHash, address exitor, uint256 oindex, bytes
                       sigs) internal view returns (bool) {
      return true;
    }

    function checkMembership(bytes32 leaf, uint256 index, bytes32 rootHash, bytes proof)
    pure
    returns (bool) { return true; }

    function getUtxoPos(bytes memory challengingTxBytes, uint256 oIndex)
    internal
    constant
    returns (uint256) { return 0; }

    function recover(bytes32 _hash, bytes _sig)
    internal
    pure
    returns (address) { return address(0); }

    struct ExitingTxWrapper {
        address exitor;
        address token;
        uint256 amount;
        uint256 inputCount;
    }

    function createExitingTx(bytes memory exitingTxBytes, uint256 oindex)
        internal
        constant
        returns (ExitingTxWrapper) {
                return ExitingTxWrapper({
                        exitor: address(0),
                        token: address(0),
                        amount: 0,
                        inputCount: 0});
    }

    /*
     * Public Functions
     */

    // @dev Allows anyone to add new token to Plasma chain
    // @param token The address of the ERC20 token
    function addToken(address _token)
        public
    {
        require(!hasToken(_token));
        exitsQueues[_token] = address(new PriorityQueue());
        TokenAdded(_token);
    }

    /**
     * @dev Allows Plasma chain operator to submit block root.
     * @param _root The root of a child chain block.
     */
    function submitBlock(bytes32 _root)
        public
        onlyOperator
    {
        uint256 submittedBlockNumber = currentChildBlock;
        childChain[currentChildBlock] = new ChildBlock(
            _root,
            block.timestamp
        );

        // Update block numbers.
        currentChildBlock = currentChildBlock + CHILD_BLOCK_INTERVAL;
        currentDepositBlock = 1;

        BlockSubmitted(submittedBlockNumber);
    }

    /**
     * @dev Allows anyone to deposit funds into the Plasma chain.
     */
    function deposit()
        public
        payable
    {
        // Only allow up to CHILD_BLOCK_INTERVAL deposits per child block.
        require(currentDepositBlock < CHILD_BLOCK_INTERVAL);

        writeDepositBlock(msg.sender, address(0), msg.value);
    }


    /**
     * @dev Deposits approved amount of ERC20 token. Approve must be called first. Note: does not check if token was added.
     */
    function depositFrom(address _owner, address _token, uint256 _amount)
        public
    {
        // Only allow up to CHILD_BLOCK_INTERVAL deposits per child block.
        require(currentDepositBlock < CHILD_BLOCK_INTERVAL);

        // Warning, check your ERC20 implementation. TransferFrom should return bool
        ERC20 tok = ERC20(_token);
        require(tok.transferFrom(_owner, address(this), _amount));
        writeDepositBlock(_owner, _token, _amount);
    }

    /**
     * @dev Starts an exit from a deposit.
     * @param _depositPos UTXO position of the deposit.
     * @param _token Token type to deposit.
     * @param _amount Deposit amount.
     */
    function startDepositExit(uint256 _depositPos, address _token, uint256 _amount)
        public
    {
        // uint256 blknum = _depositPos / UTXO_POS_BLKSIZE;
        uint256 blknum = 1; // PLACEHOLDER for div

        // Check that the given UTXO is a deposit.
        require(blknum % CHILD_BLOCK_INTERVAL != 0);

        // Validate the given owner and amount.
        ChildBlock blk = ChildBlock(childChain[blknum]);
        bytes32 root = blk.root();
        bytes32 depositHash = keccak256(a_a_i(msg.sender, _token, _amount));
        require(root == depositHash);

        addExitToQueue(_depositPos, msg.sender, _token, _amount, blk.timestamp());
    }

    /**
     * @dev Allows the operator withdraw any allotted fees. Starts an exit to avoid theft.
     * @param _token Token to withdraw.
     * @param _amount Amount in fees to withdraw.
     */
    function startFeeExit(address _token, uint256 _amount)
        public
        onlyOperator
    {
        addExitToQueue(currentFeeExit, msg.sender, _token, _amount, block.timestamp + 1);
        currentFeeExit = currentFeeExit + 1;
    }

    /**
     * @dev Starts to exit a specified utxo.
     * @param _utxoPos The position of the exiting utxo in the format of blknum * 1000000000 + index * 10000 + oindex.
     * @param _txBytes The transaction being exited in RLP bytes format.
     * @param _proof Proof of the exiting transactions inclusion for the block specified by utxoPos.
     * @param _sigs Transaction signatures are needed to check tx inclusion.
     */
    function startExit(
        uint256 _utxoPos,
        bytes _txBytes,
        bytes _proof,
        bytes _sigs
    )
        public
    {
        uint256 blknum = _utxoPos / UTXO_POS_BLKSIZE;
        uint256 txindex = (_utxoPos % UTXO_POS_BLKSIZE) / UTXO_POS_TXINDEX;
        uint256 oindex = _utxoPos - blknum * UTXO_POS_BLKSIZE - txindex * UTXO_POS_TXINDEX;

        // Check the sender owns this UTXO.
        var exitingTx = createExitingTx(_txBytes, oindex);
        require(msg.sender == exitingTx.exitor);

        // Check the transaction was included in the chain.
        ChildBlock blk = ChildBlock(childChain[blknum]);
        bytes32 root = blk.root();
        bytes32 merkleHash = keccak256(b32_b(keccak256(_txBytes), slice(_sigs, 0, 130)));
        require(checkMembership(merkleHash, txindex, root, _proof));

        addExitToQueue(_utxoPos, exitingTx.exitor, exitingTx.token, exitingTx.amount, blk.timestamp());
    }

    /**
     * @dev Allows anyone to challenge an exiting transaction by submitting proof of a double spend on the child chain.
     * @param _cUtxoPos The position of the challenging utxo.
     * @param _eUtxoIndex The output position of the exiting utxo.
     * @param _txBytes The challenging transaction in bytes RLP form.
     * @param _proof Proof of inclusion for the transaction used to challenge.
     * @param _sigs Signatures for the transaction used to challenge.
     */
    function challengeExit(
        uint256 _cUtxoPos,
        uint256 _eUtxoIndex,
        bytes _txBytes,
        bytes _proof,
        bytes _sigs
    )
        public
    {
        var txHash = keccak256(_txBytes);
        uint256 eUtxoPos = getUtxoPos(_txBytes, _eUtxoIndex);
        Exit e = Exit(exits[eUtxoPos]);
        uint256 blknum = _cUtxoPos / UTXO_POS_BLKSIZE;
        uint256 txindex = (_cUtxoPos % UTXO_POS_BLKSIZE) / UTXO_POS_TXINDEX;
        uint256 oindex = _cUtxoPos - blknum * UTXO_POS_BLKSIZE - txindex * UTXO_POS_TXINDEX;

        // Check if double-spend was signed by utxo owner.
        require(checkSigs(txHash, e.owner(), oindex, _sigs));

        // Check if spending transaction was included.
        ChildBlock cblk = ChildBlock(childChain[_cUtxoPos / UTXO_POS_BLKSIZE]);
        var merkleHash = keccak256(b32_b(txHash, _sigs));
        require(checkMembership(merkleHash, txindex, cblk.root(), _proof));

        // Delete the owner but keep the amount to prevent another exit.
        e.delOwner();
    }

    function VERY_VERY_INVALID() private {}
    function CONSTRAINT_VALID() private {}

    function CHECK_INVALID_CALLWITH_1(uint256 x) private {
       if (x == 2) {
           VERY_VERY_INVALID();
       } else {
           CONSTRAINT_VALID();
       }
    }

    /**
     * @dev Processes exits that have completed the challenge period.
     * @param _token Token type to process.
     * @param _topUtxoPos First exit that should be processed. Set to zero to skip the check.
     * @param _exitsToProcess Maximal number of exits to process.
     */
    function finalizeExits(address _token, uint256 _topUtxoPos, uint256 _exitsToProcess)
        public
    {
        uint256 utxoPos;
        uint256 exitable_at;
        uint256 _exitsLeft = _exitsToProcess;
        address owner;
        uint256 amt;
        CHECK_INVALID_CALLWITH_1(1);

        utxoPos = getNextExitPosition(_token);
        exitable_at = getNextExitTime(_token);
        require(_topUtxoPos == utxoPos || _topUtxoPos == 0);
        Exit currentExit = Exit(exits[utxoPos]);
        PriorityQueue queue = PriorityQueue(exitsQueues[_token]);
        CHECK_INVALID_CALLWITH_1(1);
        while (exitable_at < block.timestamp && _exitsLeft > 0) {

            currentExit = Exit(exits[utxoPos]);
            owner = currentExit.owner();
            amt = currentExit.amount();

            queue.delMin();

            // Send funds only if exit was not successfully challenged.
            if (owner != address(0)) {
                if (_token == address(0)) {
                    if (!owner.call.value(amt)()) { revert(); }
                } else {
                    ERC20 tt = ERC20(_token);
                    require(tt.transfer(owner, amt));
                }
            }
            // delete exits[utxoPos].owner;
            currentExit.delOwner();

            if (queue.currentSize() > 0) {
                NONEMPTY_QUEUE();
                // utxoPos = getNextExitPosition(_token);
                // exitable_at = getNextExitTime(_token);
                _exitsLeft = _exitsLeft - 1;
            } else {
                EMPTY_QUEUE();
                return;
            }
        }
    }

    function NONEMPTY_QUEUE() private { }
    function EMPTY_QUEUE() private { }

    /*
     * Public view functions
     */

    /**
     * @dev Checks if queue for particular token was created.
     * @param _token Address of the token.
     */
    function hasToken(address _token)
        view
        public
        returns (bool)
    {
        return exitsQueues[_token] != address(0);
    }

    /**
     * @dev Queries the child chain.
     * @param _blockNumber Number of the block to return.
     * @return Child chain block at the specified block number.
     */
    function getChildChainRoot(uint256 _blockNumber)
        public
        view
        returns (bytes32)
    {
        ChildBlock blk = ChildBlock(childChain[_blockNumber]);
        return blk.root();
    }

    function getChildChainTimestamp(uint256 _blockNumber)
        public
        view
        returns (uint256)
    {
        ChildBlock blk = ChildBlock(childChain[_blockNumber]);
        return blk.timestamp();
    }

    /**
     * @dev Determines the next deposit block number.
     * @return Block number to be given to the next deposit block.
     */
    function getDepositBlock()
        public
        view
        returns (uint256)
    {
        return currentChildBlock - CHILD_BLOCK_INTERVAL + currentDepositBlock;
    }

    /**
     * @dev Returns information about an exit.
     * @param _utxoPos Position of the UTXO in the chain.
     * @return A tuple representing the active exit for the given UTXO.
     */
    function getExitOwner(uint256 _utxoPos)
        public
        view
        returns (address)
    {
        Exit e = Exit(exits[_utxoPos]);
        return e.owner();
    }

    function getExitToken(uint256 _utxoPos)
        public
        view
        returns (address)
    {
        Exit e = Exit(exits[_utxoPos]);
        return e.token();
    }

    function getExitAmount(uint256 _utxoPos)
        public
        view
        returns (uint256)
    {
        Exit e = Exit(exits[_utxoPos]);
        return e.amount();
    }

    /**
     * @dev Determines the next exit to be processed.
     * @param _token Asset type to be exited.
     * @return Position when this exit can be processed.
     */
    function getNextExitPosition(address _token)
        public
        view
        returns (uint256)
    {
        PriorityQueue queue = PriorityQueue(exitsQueues[_token]);
        uint256 utxoPos = queue.getMinLowBits();
        return utxoPos;
    }

    /**
     * @dev Determines the next exit to be processed.
     * @param _token Asset type to be exited.
     * @return Time when this exit can be processed.
     */
    function getNextExitTime(address _token)
        public
        view
        returns (uint256)
    {
        PriorityQueue queue = PriorityQueue(exitsQueues[_token]);
        uint256 exitable_at = queue.getMinHighBits();
        return exitable_at;
    }


    /*
     * Private functions
     */

    /**
     * @dev Placeholder function that abstract polymorphism of `keccak256`
     */
    function a_a_i(address x, address y, uint256 i) returns (bytes) {
      return placeholder;
    }

    /**
     * @dev Placeholder function that abstract polymorphism of `keccak256`
     */
    function b_b(bytes b1, bytes b2) returns (bytes) {
      return placeholder;
    }

    /**
     * @dev Placeholder function that abstract polymorphism of `keccak256`
     */
    function b32_b(bytes32 b1, bytes b2) returns (bytes) {
      return placeholder;
    }

    /**
     * @dev Placeholder function that abstract polymorphism of `keccak256`
     */
    function b_b32(bytes32 b1, bytes32 b2) returns (bytes) {
      return placeholder;
    }

    /**
     * @dev Adds deposit block to chain of blocks.
     * @param _owner Owner of deposit and created UTXO.
     * @param _token Deposited token (0x0 represents ETH).
     * @param _amount The amount deposited.
     */
    function writeDepositBlock(address _owner, address _token, uint256 _amount)
        private
    {
        // Following check is needed since writeDepositBlock
        // can be called on stack unwinding during re-entrance attack,
        // with currentDepositBlock == 999, producing
        // deposit with blknum ending with 000.
        require(currentDepositBlock < CHILD_BLOCK_INTERVAL);

        bytes32 root = keccak256(a_a_i(_owner, _token, _amount));
        uint256 depositBlock = getDepositBlock();
        childChain[depositBlock] = new ChildBlock(
            root,
            block.timestamp
        );
        currentDepositBlock = currentDepositBlock + 1;

        Deposit(_owner, depositBlock, _token, _amount);
    }


    /**
     * @dev Adds an exit to the exit queue.
     * @param _utxoPos Position of the UTXO in the child chain.
     * @param _exitor Owner of the UTXO.
     * @param _token Token to be exited.
     * @param _amount Amount to be exited.
     * @param _created_at Time when the UTXO was created.
     */
    function addExitToQueue(
        uint256 _utxoPos,
        address _exitor,
        address _token,
        uint256 _amount,
        uint256 _created_at
    )
        private
    {
        // Check that we're exiting a known token.
        require(exitsQueues[_token] != address(0));

        // Calculate priority.
        uint256 exitable_A = _created_at + 2 weeks;
        uint256 exitable_B = block.timestamp + 1 weeks;
        uint256 exitable_at;
        if (exitable_A > exitable_B)
             exitable_at = exitable_A;
        else
             exitable_at = exitable_B;

        // Check exit is valid and doesn't already exist.
        require(_amount > 0);
        // Synthetic Minds: Skip this test as uses Solidity's feature of returning 0-init
        // values when the keys are unset. I.e., in Solidity, maps are complete.
        //// Exit e = Exit(exits[_utxoPos]);
        //// require(e.amount() == 0);

        PriorityQueue queue = PriorityQueue(exitsQueues[_token]);
        queue.insert(exitable_at, _utxoPos);

        CHECK_INVALID_CALLWITH_1(1);

        exits[_utxoPos] = new Exit(
            _exitor,
            _token,
            _amount
        );

        CHECK_INVALID_CALLWITH_1(1);

        ExitStarted(msg.sender, _utxoPos, _token, _amount);
    }
}

contract EvalQueue {
    function nondet(uint256 id) pure returns (uint256) { return 0; }
    function main() view public {
      uint256 a = nondet(0);
      uint256 b = nondet(1);
      uint256 x = nondet(2);
      uint256 y = nondet(3);
      PriorityQueue pq = new PriorityQueue();
      pq.insert(a, b);
      pq.insert(x, y);
      uint256 mH = pq.getMinHighBits();
      uint256 mL = pq.getMinLowBits();

      // a < x => min = (a, b)
      assert(a >= x || (mH == a && mL == b));
      // x < a => min = (x, y)
      assert(x >= a || (mH == x && mL == y));
      // x = a && b < y => min = (a, b)
      assert(x != a || b >= y || (mH == a && mL == b));
      // x = a && y < b => min = (x, y)
      assert(x != a || y >= b || (mH == x && mL == y));
    }
}
