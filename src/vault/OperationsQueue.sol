/**
 * Base logic for the vault operations queue,
 * which enables queueing on operations locks, for a robust working
 * system even with offchain interverience
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "./Schema.sol";
import "forge-std/console.sol";

abstract contract OperationsQueue is IVault {
    // =====================
    //       STORAGE
    // =====================
    /**
     * @dev An operation "lock" mechanism,
     * This is set to true when an operation (Strategy run, deposit, withdrawal, etc) begins, and false when it ends -
     * And prevents execution of fullfils in the offchain queue of other operations until this becomes false,
     */
    bool locked;

    // ==============================
    //      OPERATIONS MANAGER
    // ==============================
    /*********************************************************
     * @notice
     * Since all of our operations (strategy run, deposits, withdrawals...) may include mid-way
     * offchain computations, it is required to keep a queue and a lock in order for them to execute one-by-one
     * in an order, and not clash.
     *********************************************************/

    /**
     * @dev Mapping keeping track of indexes to queued operations
     */
    mapping(uint256 => QueueItem) internal operationsQueue;

    /**
     * @dev We manually keep track of the current "front" and "rear" indexes of the queue
     */
    uint256 front;
    uint256 rear;

    /**
     * @dev Enqueue a queue item
     */
    function enqueueOp(QueueItem memory queueItem) internal {
        operationsQueue[rear] = queueItem;
        rear++;

        /**
         * @notice
         * We check to see if the state is currently locked. If it isnt, and we are the first one in the queue,
         * we simply call the routeQueueOperation(), and handle the request immediatly.
         * Otherwise We emit a RequestFullfill event, with the action called "handle_ops_queue", which will, in turn,
         * simply begin handling the queue offchain, taking in mind the lock state.
         * This allows the intervention of the offchain only when required.
         */
        if (!locked && front == rear - 1) {
            // This is a new request so starting indices would always be just the root step,
            // and the fullfill command empty.
            uint256[] memory startingIndices = new uint256[](1);
            startingIndices[0] = 0;
            routeQueueOperation(startingIndices, new bytes(0));
        } else
            emit RequestFullfill(
                // Action is just used randomly, does not matter here
                queueItem.action,
                "handle_ops_queue",
                0,
                new bytes[](0)
            );
    }

    /**
     * @dev Dequeue and retreive a queue item
     */
    function dequeueOp() internal returns (QueueItem memory currentItem) {
        require(front < rear, "Queue Is Empty");

        currentItem = operationsQueue[front];

        delete operationsQueue[front];

        front++;

        // We reset front & rear to zero if the queue is empty, to save on future gas
        if (front < rear) {
            front = 0;
            rear = 0;
        }
    }
}
