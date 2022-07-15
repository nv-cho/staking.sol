// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Staking {
    IERC20 public s_stakingToken;
    IERC20 public s_rewardToken;

    //address -> te informa cuanto ha stakeado
    mapping(address => uint256) public s_balances;

    //reward que obtiene cada address
    mapping(address => uint256) public s_rewards;
    // cuando se le ha pagado a cada usuario x cantidad de tokens
    mapping(address => uint256) public s_userRewardPerTokenPaid;

    //total de tokens bloqueados
    uint256 public s_totalSupply;

    // cantdidad de reward x token bloqueado;
    uint256 public s_rewardPerTokenStored;

    //la ultima vez que se ejecuto el modifier updateReward
    uint256 public s_lastUpdateTime;

    //cantidad de reward por segundo!!
    uint256 public constant REWARD_RATE = 100;

    constructor(address _stakingToken, address _rewardToken) {
        s_stakingToken = IERC20(_stakingToken);
        s_rewardToken = IERC20(_rewardToken);
    }

    modifier updateReward(address account) {
        // reward x token
        // ultimo timestamp

        s_rewardPerTokenStored = rewardPerToken();
        s_lastUpdateTime = block.timestamp;
        // crear mapping para guardar las rewards
        // basado en el resultado de una funcion que llamaremos earned

        s_rewards[account] = earned(account);
        s_userRewardPerTokenPaid[account] = s_rewardPerTokenStored;
        _;
    }

    modifier moreThanZero(uint256 amount) {
        require(amount > 0, "Amount must be greater than 0");
        _;
    }

    function earned(address account) public view returns (uint256) {
        // balance de lo que se ha stakeado
        uint256 currentBalance = s_balances[account];
        // cuanto han recibido
        uint256 amountPaid = s_userRewardPerTokenPaid[account];
        uint256 currentRewardPerToken = rewardPerToken();
        uint256 pastRewards = s_rewards[account];
        uint256 totalEarned = ((currentBalance *
            (currentRewardPerToken - amountPaid)) / 1e18) + pastRewards;
        return totalEarned;
    }

    function rewardPerToken() public view returns (uint256) {
        if (s_totalSupply == 0) {
            return s_rewardPerTokenStored;
        }

        return
            s_rewardPerTokenStored +
            (((block.timestamp - s_lastUpdateTime) * REWARD_RATE * 1e18) /
                s_totalSupply);
    }

    // obtener el reward o reclamar el reward

    function claimReward() external updateReward(msg.sender) {
        //cuanta recompensa obtendrá el usuario?
        // tokens x segundo y los reparte a los stakers
        // 100 reward token x second

        uint256 reward = s_rewards[msg.sender];
        s_rewards[msg.sender] = 0;
        bool success = s_rewardToken.transfer(msg.sender, reward);
        require(success, "ClaimReward: Fallo la tx");
    }

    function stake(uint256 amount)
        external
        updateReward(msg.sender)
        moreThanZero(amount)
    {
        // Almacenamos registro de cuando el usuario ha stakeado
        // Tener un conteo total de los tokens
        // Transferir tokens a este contrato!!!
        s_balances[msg.sender] = s_balances[msg.sender] + amount;
        s_totalSupply = s_totalSupply + amount;
        bool success = s_stakingToken.transferFrom(
            msg.sender,
            address(this),
            amount
        );
        require(success, "Staking: Fallo la tx");
        //emit evento
    }

    function withdraw(uint256 amount)
        external
        updateReward(msg.sender)
        moreThanZero(amount)
    {
        s_balances[msg.sender] = s_balances[msg.sender] - amount;
        s_totalSupply = s_totalSupply - amount;
        bool success = s_stakingToken.transfer(msg.sender, amount);
        require(success, "Withdraw: Fallo la tx");
    }
}
