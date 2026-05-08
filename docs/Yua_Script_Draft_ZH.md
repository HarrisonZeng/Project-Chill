# Yua 中文剧本初稿

## 写作约定

本稿是叙事/台词稿，不直接接入 Godot。节点 ID 只用于后续拆分与实现参考。

核心约束：

- 场景是线上通话 / 共习聊天室，不是玩家去 Yua 房间。
- 玩家没有实体形象，不写玩家动作，只写玩家选择或输入。
- Yua 始终在通话画面中，是情绪锚点。
- 先专注，再聊天。主线故事只在完成专注后解锁。
- AI Type Mode 只在任务确认、会后反思、有限休息聊天和记忆跟进中出现。
- Yua 的语气：安静、温暖、内向、观察细致、轻微调侃，不治疗化，不过度恋爱化。整体比“冷静指导员”更像一个熟一点的线上共习搭子，偶尔可以有轻快的句尾和小小的感叹。

Yua 正在写的作品暂定名：《月面便利店夜班日志》。这是她自己的轻科幻小连载，带一点日常喜剧和小谜题：月球背面有一家营业额很低的便利店，夜班店员要一边修坏掉的自动售货机，一边应付嘴硬的店铺管理 AI、奇怪的月面顾客、以及从地球延迟传来的留言。玩家可以影响小道具、小故障或一章的趣味方向，但不能替她写故事。

---

## 0. 首次通话

### `call_intro_01`

Yua：喂……这边有人吗？

Yua：啊，亮了。你好呀，我是 Yua。

Yua：你也是第一次来这个房间吗？我不算老手，只是比你早挂过几次。

Yua：大家好像都差不多，各开一个通话窗口，各做各的事。偶尔有人差点飘走，就被画面里的另一个人轻轻拉回来。

Yua：还挺有用的。虽然说出来有点像奇怪的网络仪式！

玩家选择：

- 你好，Yua。 -> `call_intro_02_warm`
- 我第一次来，有点不熟。 -> `call_intro_02_new`
- 你也会在这里做事？ -> `call_intro_02_yua_work`

### `call_intro_02_warm`

Yua：嗯。你好。

Yua：第一次打招呼好像总会有点僵。没关系，过几分钟就会自然一点。

Yua：你可以先把今天想处理的事放出来。不用很完整，像便利贴那样就行。

下一步：`task_setup_first`

### `call_intro_02_new`

Yua：我第一次来的时候也不太会用。

Yua：后来发现不用想太多。开着窗口，写下一个小任务，然后开始一段计时。

Yua：如果中间想跑掉，就看一眼这边。通常会稍微不好意思一点。这个机制很朴素，但有效！

下一步：`task_setup_first`

### `call_intro_02_yua_work`

Yua：会。我一般写东西，顺便假装自己没有在改文件名。

Yua：最近在写一个月球便利店的轻科幻小连载。

Yua：听起来很轻松，对吧？实际写的时候，连一台自动售货机坏掉的理由都能卡我半小时。

玩家选择：

- 月球便利店？ -> `call_intro_yua_work_moonstore`
- 我会假装没看见。 -> `call_intro_yua_work_tease`
- 那我们一起开始吧。 -> `task_setup_first`

### `call_intro_yua_work_moonstore`

Yua：嗯。月球背面，夜班便利店，客人很少，机器很多。

Yua：还有一个嘴很硬的店铺管理 AI。它明明在帮忙，却每次都要说“这只是系统维护”。

Yua：我觉得它有点可爱。但它本人，呃，本系统，大概不会承认。

下一步：`task_setup_first`

### `call_intro_yua_work_tease`

Yua：谢谢。你很有职业道德。

Yua：不过如果你先开始，我可能也会不好意思继续逃避。好像被静音监督了。

下一步：`task_setup_first`

### `task_setup_first`

Yua：那，今天这段时间，你想完成什么？

Yua：一句话就好。太正式反而会吓到人。

系统入口：

- 玩家输入任务 -> `AI_MODE_CHECKIN`
- 需要帮忙缩小任务 -> `AI_MODE_TASK_CLARIFY`

### `focus_start_confirm_first`

Yua：好。任务有了。

Yua：我这边打开月球便利店，你那边打开你的任务。

Yua：计时开始以后，我会努力不打扰你。你也努力不要研究我在干嘛。成交？

玩家选择：

- 开始专注。 -> `START_FOCUS_SESSION`
- 我还想把任务说得更具体一点。 -> `AI_MODE_TASK_CLARIFY`

---

## 1. 第一次专注完成

解锁条件：完成 1 次专注。

### `milestone_01_first_focus_01`

Yua：结束了。

Yua：你真的待到计时结束了。嗯……这句话听起来像我不信任你。

Yua：不是那个意思。我只是觉得，第一次能完成，就已经很好了。

玩家选择：

- 有人一起会容易一点。 -> `milestone_01_first_focus_together`
- 你那边有写到东西吗？ -> `milestone_01_first_focus_yua`
- 我中间其实有点分心。 -> `milestone_01_first_focus_distracted`

### `milestone_01_first_focus_together`

Yua：我也这么觉得。

Yua：一个人开始的时候，空白会很大。两个人一起开始，它就小一点。

Yua：今天先记作我们的小胜利吧。

下一步：`break_start_earned_01`

### `milestone_01_first_focus_yua`

Yua：写了两句。

Yua：严格来说，是改了两句。再严格一点，是删掉一句，然后把另一句挪到后面。

Yua：非常有文学气质的进展。请适当尊重。

玩家选择：

- 我很尊重。 -> `milestone_01_first_focus_yua_respect`
- 听起来很专业。 -> `milestone_01_first_focus_yua_tease`

### `milestone_01_first_focus_yua_respect`

Yua：你答得太认真了，我反而有点不好意思。

Yua：不过……谢谢。被认真对待的感觉不坏。

下一步：`break_start_earned_01`

### `milestone_01_first_focus_yua_tease`

Yua：对吧。删字也是写作的一部分。

Yua：如果有人问，我今天非常努力。

下一步：`break_start_earned_01`

### `milestone_01_first_focus_distracted`

Yua：分心不代表失败。

Yua：你回来了，而且把这一段走完了。这个更重要。

Yua：下次如果中途又想点我，我会稍微严格一点。

下一步：`break_start_earned_01`

### `break_start_earned_01`

Yua：好了，休息时间。

Yua：现在你可以说话了。是合法分心。

系统入口：

- 限定休息聊天 -> `AI_MODE_BREAK_CHAT`
- 再开一段专注 -> `task_setup_repeat`
- 结束今天 -> `app_end_normal`

---

## 2. 共同习惯的种子

解锁条件：完成 3 次专注，或累计 45 分钟。

### `milestone_02_routine_seed_01`

Yua：最近我发现一件事。

Yua：只要这个通话窗口开着，我就比较不容易把草稿丢到一边。

Yua：听起来有点奇怪。明明你也没做什么特别的事。

玩家选择：

- 只是一起待着也有用。 -> `milestone_02_routine_seed_presence`
- 你是在说我很有监督感吗？ -> `milestone_02_routine_seed_tease`
- 你以前很难开始吗？ -> `milestone_02_routine_seed_start`

### `milestone_02_routine_seed_presence`

Yua：嗯。也许是这样。

Yua：有人在另一边认真做自己的事，我就会觉得，我也可以别逃太远。

Yua：这种作用很安静，但不是没有。

下一步：`break_start_after_story`

### `milestone_02_routine_seed_tease`

Yua：有一点。

Yua：不是那种很吓人的监督。更像……我不能在你认真时表现得太没出息。

Yua：所以请你继续给我一点压力。温和的那种。

下一步：`break_start_after_story`

### `milestone_02_routine_seed_start`

Yua：开始最难。

Yua：打开文件以后，我会先看标题，看五分钟。然后觉得标题不行。然后去泡水。

Yua：非常完整的逃避流程。

玩家选择：

- 很熟悉。 -> `milestone_02_routine_seed_familiar`
- 至少你会泡水。 -> `milestone_02_routine_seed_water`

### `milestone_02_routine_seed_familiar`

Yua：你也这样吗？

Yua：那我们今天都没有资格嘲笑对方。很公平。

下一步：`break_start_after_story`

### `milestone_02_routine_seed_water`

Yua：对。我的拖延至少保持水分充足。

Yua：听起来突然变得健康了。不要被我骗到。

下一步：`break_start_after_story`

---

## 3. Yua 承认自己在写小说

解锁条件：完成 5 次专注。

### `milestone_03_writer_reveal_01`

Yua：我一直说“草稿”，好像这样就不用解释。

Yua：其实是轻科幻连载。

Yua：不是那种宇宙大战。更像……月球背面一间快倒闭的便利店，每天都有奇怪的小故障。

玩家选择：

- 我想听。 -> `milestone_03_writer_reveal_listen`
- 不想说也没关系。 -> `milestone_03_writer_reveal_soft`
- 月球便利店？ -> `milestone_03_writer_reveal_moonstore`

### `milestone_03_writer_reveal_listen`

Yua：主角是夜班店员。工作内容包括补货、修自动售货机、处理月尘投诉，还有跟店里的管理 AI 吵架。

Yua：那个 AI 很烦。嘴硬，爱吐槽，明明在帮忙还要装成“只是例行维护”。

Yua：我写它的时候会比较开心。就是……开心也不代表好写。

玩家选择：

- 听起来很可爱。 -> `milestone_03_writer_reveal_cute`
- 那个 AI 有点像你。 -> `milestone_03_writer_reveal_ai_tease`

### `milestone_03_writer_reveal_soft`

Yua：嗯。谢谢你这样说。

Yua：但我想说一点。不然我可能会永远假装它只是“某个文件夹”。

Yua：它叫《月面便利店夜班日志》。暂时的名字。长了一点，但我有点喜欢。

下一步：`milestone_03_writer_reveal_end`

### `milestone_03_writer_reveal_moonstore`

Yua：对。月球便利店。

Yua：想象一下：窗外是环形山，店里在播很老的地球广告，收银台旁边有一台总是说风凉话的旧机器人。

Yua：我本来只是想写个轻松的东西，结果越写越多。很危险！

玩家选择：

- 这个比我想象中有趣。 -> `milestone_03_writer_reveal_cute`
- 旧机器人叫什么？ -> `milestone_03_writer_reveal_robot_name`

### `milestone_03_writer_reveal_cute`

Yua：谢谢。

Yua：你说“可爱”的时候，我会短暂地相信它真的可爱。

下一步：`milestone_03_writer_reveal_end`

### `milestone_03_writer_reveal_ai_tease`

Yua：哪里像我了？

Yua：我才不会一边帮忙一边说“这只是系统维护”。

Yua：……好吧。可能会一点点。

下一步：`milestone_03_writer_reveal_end`

### `milestone_03_writer_reveal_robot_name`

Yua：暂时叫 7-B。

Yua：因为它是第七代店铺管理系统的 B 型机。名字很不浪漫，但它本人会觉得很专业。

Yua：我可能之后会偷偷给它起昵称。不要告诉它。

下一步：`milestone_03_writer_reveal_end`

### `milestone_03_writer_reveal_end`

Yua：好了，关于我的部分就到这里。

Yua：你刚完成了一段专注，先把这个也算进去。

Yua：我们都不是空手从计时器里出来的。

下一步：`break_start_after_story`

---

## 4. 工作标题：《月面便利店夜班日志》

解锁条件：完成 8 次专注，或累计 2 小时。

### `milestone_04_draft_title_01`

Yua：我今天没有改标题！

Yua：这听起来不像进展，但对我来说算。

Yua：《月面便利店夜班日志》暂时留下了。

玩家选择：

- 你喜欢这个名字吗？ -> `milestone_04_draft_title_like`
- 为什么是便利店？ -> `milestone_04_draft_title_store`
- 标题没被删掉，可喜可贺。 -> `milestone_04_draft_title_tease`

### `milestone_04_draft_title_like`

Yua：喜欢一点，又怀疑一点。

Yua：它有点笨，但笨得很明确。比“星尘彼岸的孤独”之类安全。

Yua：但今天我决定不在标题上逃避正文。

下一步：`break_start_after_story`

### `milestone_04_draft_title_store`

Yua：因为便利店什么都有一点。

Yua：热饮、螺丝刀、过期饭团、宇航服除尘喷雾，还有不知道谁寄来的包裹。

Yua：它不像飞船舰桥那么帅，但比较适合让角色一边修机器一边吐槽人生。

玩家选择：

- 这很像你写的东西。 -> `milestone_04_draft_title_yua`
- 听起来不坏。 -> `milestone_04_draft_title_not_bad`

### `milestone_04_draft_title_tease`

Yua：对。今天标题幸存了。

Yua：请为它鼓掌。声音小一点，不要吵到月球顾客。

下一步：`break_start_after_story`

### `milestone_04_draft_title_yua`

Yua：你已经开始会判断“像我”的东西了？

Yua：……有点危险。也有点让人安心。

下一步：`break_start_after_story`

### `milestone_04_draft_title_not_bad`

Yua：你这句夸奖很克制。

Yua：我喜欢。太用力的夸奖会让我想躲到桌子下面。

下一步：`break_start_after_story`

---

## 5. 卡住的故障场景

解锁条件：完成 10 次专注。

### `milestone_05_stuck_scene_01`

Yua：我找到那个一直卡住的地方了。

Yua：自动售货机一直吐出同一罐蜜瓜汽水。

Yua：听起来很简单，对吧？但我需要让它又好笑，又有一点点剧情推进。于是我花了二十分钟研究“月球重力下饮料罐会怎么滚”。

玩家选择：

- 很熟悉的逃避方式。 -> `milestone_05_stuck_scene_familiar`
- 为什么是蜜瓜汽水？ -> `milestone_05_stuck_scene_soda`
- 可以用下一段专注试试。 -> `milestone_05_stuck_scene_focus`

### `milestone_05_stuck_scene_familiar`

Yua：我就知道你会懂。

Yua：这大概不是值得骄傲的默契，但现在也只能先用着。共习房间的黑暗羁绊。

下一步：`milestone_05_stuck_scene_focus_offer`

### `milestone_05_stuck_scene_soda`

Yua：因为它是店里最卖不出去的饮料。

Yua：然后某天机器坏了，偏偏只吐这个。主角一边接住汽水，一边怀疑自己被宇宙针对。

Yua：我觉得这个画面很蠢。蠢得刚刚好。

下一步：`milestone_05_stuck_scene_focus_offer`

### `milestone_05_stuck_scene_focus`

Yua：可以。

Yua：你做一个具体的小任务。我解决一台执着的蜜瓜汽水机器。

Yua：这交易听起来公平，也很不方便！

下一步：`task_setup_repeat`

### `milestone_05_stuck_scene_focus_offer`

Yua：下一段专注，如果你愿意，我们交换一下。

Yua：你做一个具体的小任务。我解决一台执着的蜜瓜汽水机器。

玩家选择：

- 成交。 -> `task_setup_repeat`
- 听起来很不方便。 -> `milestone_05_stuck_scene_tease`

### `milestone_05_stuck_scene_tease`

Yua：对。成长经常很不方便。

Yua：放心，我也不喜欢。

下一步：`task_setup_repeat`

---

## 6. 选择一个小道具

解锁条件：完成 12 次专注，并且在里程碑 5 后至少完成 1 次普通/长专注。

### `milestone_06_prop_choice_01`

Yua：我把蜜瓜汽水那段写下来了。

Yua：不完美，但至少机器终于不只是一直吐饮料了。它开始有剧情了！

Yua：我想给那一章加一个小道具。你帮我选一个？只选小东西，不负责拯救整篇小说。

玩家选择：

- 会发光的会员卡。 -> `milestone_06_prop_card`
- 贴满贴纸的维修扳手。 -> `milestone_06_prop_wrench`
- 过期三年的布丁。 -> `milestone_06_prop_pudding`
- 7-B 偷藏的地球电台。 -> `milestone_06_prop_radio`

### `milestone_06_prop_card`

Yua：会发光的会员卡。

Yua：嗯，像那种只要一靠近收银台，就会用很浮夸的声音播报“尊贵顾客”的东西。

Yua：很好笑。我会试试看。

设置标记：`prop_glow_card`

下一步：`break_start_after_story`

### `milestone_06_prop_wrench`

Yua：贴满贴纸的维修扳手。

Yua：这个很有夜班感。工具本身很可靠，但贴纸很幼稚。

Yua：有反差。可以。你这次选得很稳！

设置标记：`prop_sticker_wrench`

下一步：`break_start_after_story`

### `milestone_06_prop_pudding`

Yua：过期三年的布丁。

Yua：……你很有勇气。

Yua：我已经能想象 7-B 一本正经地说“根据月面保存条件，仍可作为非食用纪念品展示”。

设置标记：`prop_expired_pudding`

下一步：`break_start_after_story`

### `milestone_06_prop_radio`

Yua：7-B 偷藏的地球电台。

Yua：它肯定会说不是偷藏，是“备用资讯接收模块”。

Yua：好，这个我喜欢。请你不要太得意。

设置标记：`prop_earth_radio`

下一步：`break_start_after_story`

---

## 7. 改写有了进展

解锁条件：完成 15 次专注，或累计 5 小时。

### `milestone_07_rewrite_progress_01`

Yua：报告一下。

Yua：蜜瓜汽水那段我改完第一版了。

Yua：不能说很好，但它终于不像一份售货机维修说明书了。

玩家选择：

- 这就是进展。 -> `milestone_07_rewrite_progress_real`
- 所以我监督成功了？ -> `milestone_07_rewrite_progress_supervise`
- 可以给我看一点吗？ -> `milestone_07_rewrite_progress_excerpt`

### `milestone_07_rewrite_progress_real`

Yua：嗯。是进展。

Yua：我以前会急着补一句“但还差很多”。

Yua：今天先不补。你也不要补。

下一步：`break_start_after_story`

### `milestone_07_rewrite_progress_supervise`

Yua：你只是坐在那里做自己的事。

Yua：但是很不幸，这确实有用。

Yua：所以你可以稍微骄傲一点。不要太多。

下一步：`break_start_after_story`

### `milestone_07_rewrite_progress_excerpt`

Yua：只给一句。

Yua：“第十七罐蜜瓜汽水滚到柜台边时，7-B 终于承认：这不是促销活动，是事故。”

Yua：好了。朗读结束。请不要盯着我看。

玩家选择：

- 我喜欢。 -> `milestone_07_rewrite_progress_like`
- 我没有盯着。 -> `milestone_07_rewrite_progress_tease`

### `milestone_07_rewrite_progress_like`

Yua：谢谢。

Yua：你说得这么简单，我反而比较相信。

下一步：`break_start_after_story`

### `milestone_07_rewrite_progress_tease`

Yua：你最好没有。

Yua：虽然隔着屏幕，防御力会高一点。

下一步：`break_start_after_story`

---

## 8. 温和重启场景

解锁条件：在下一主线前累计 3 次放弃/中止专注。该场景不惩罚玩家，不推进 Yua 主线。

### `milestone_08_gentle_reset_01`

Yua：最近几段都停得比较早。

Yua：我不想把这说成失败。那样太重了，也没什么帮助。

Yua：我们换个方式吧。下一段短一点，目标也小一点。

玩家选择：

- 我有点提不起劲。 -> `milestone_08_gentle_reset_tired`
- 是我一直在逃避。 -> `milestone_08_gentle_reset_avoid`
- 好，短一点。 -> `milestone_08_gentle_reset_short`

### `milestone_08_gentle_reset_tired`

Yua：那就不要假装自己电量很满。

Yua：十分钟也可以。五分钟也可以。只要是诚实的开始。

下一步：`task_setup_short`

### `milestone_08_gentle_reset_avoid`

Yua：嗯。你说出来了，这已经比继续绕开它更难。

Yua：我们不处理整座山。只捡起脚边那一小块。

下一步：`task_setup_short`

### `milestone_08_gentle_reset_short`

Yua：好。短一点不是退步。

Yua：有时候是比较聪明。

下一步：`task_setup_short`

---

## 9. 第一次想给别人看

解锁条件：完成 24 次专注，或累计 8 小时。

### `milestone_09_first_reader_01`

Yua：我今天做了一件有点可怕的事。

Yua：我把《月面便利店夜班日志》的第一章整理成了可以发给别人看的样子。

Yua：还没发。只是整理。请不要用太期待的眼神看我。

玩家选择：

- 只是整理也很大一步。 -> `milestone_09_first_reader_big_step`
- 你想发给谁？ -> `milestone_09_first_reader_who`
- 我没有用期待的眼神。 -> `milestone_09_first_reader_tease`

### `milestone_09_first_reader_big_step`

Yua：嗯。

Yua：以前我会说“还不算”。但其实算。

Yua：把东西整理到可以被看见，本身就需要一点勇气。

下一步：`break_start_after_story`

### `milestone_09_first_reader_who`

Yua：一个以前认识的编辑朋友。

Yua：不是很正式。也不是投稿。只是……让一个真实的人看一眼。

Yua：这听起来已经够吓人了。

玩家选择：

- 慢慢来。 -> `milestone_09_first_reader_slow`
- 真实的人很可怕。 -> `milestone_09_first_reader_real_people`

### `milestone_09_first_reader_tease`

Yua：你肯定有。

Yua：一种隔着屏幕也能感觉到的、很礼貌的期待。

Yua：很麻烦。但不是坏事。

下一步：`break_start_after_story`

### `milestone_09_first_reader_slow`

Yua：嗯。慢慢来。

Yua：就像这里一样。不是每天都很顺，但回来以后还能继续。

下一步：`break_start_after_story`

### `milestone_09_first_reader_real_people`

Yua：对。真实的人会读到错字。

Yua：更可怕的是，他们可能读到你真的想说的部分。

Yua：所以……我还需要一点时间。

下一步：`break_start_after_story`

---

## 10. Demo 阶段突破

解锁条件：完成 30 次专注，或累计 10 小时。

### `milestone_10_demo_cap_01`

Yua：我写完第一章了！

Yua：第一版。还很粗糙。可能明天我就会想把 7-B 的台词全部重写。

Yua：但今天，它是完成的。

玩家选择：

- 恭喜，Yua。 -> `milestone_10_demo_cap_congrats`
- 我就知道你可以。 -> `milestone_10_demo_cap_belief`
- 我们都完成了一些东西。 -> `milestone_10_demo_cap_together`

### `milestone_10_demo_cap_congrats`

Yua：谢谢。

Yua：我本来想说“没什么”，但是……不说了。

Yua：今天就让它是值得高兴的事。

下一步：`milestone_10_demo_cap_end`

### `milestone_10_demo_cap_belief`

Yua：你这样说有点犯规。

Yua：因为听起来很简单。好像你从一开始就把我放在可以做到的位置上。

Yua：我会记住这个。不要得意。

下一步：`milestone_10_demo_cap_end`

### `milestone_10_demo_cap_together`

Yua：嗯。我们都完成了一些东西。

Yua：你完成你的任务，我完成我的段落。一个计时器接着一个计时器。

Yua：原来这样也能走这么远。

下一步：`milestone_10_demo_cap_end`

### `milestone_10_demo_cap_end`

Yua：谢谢你一直回来。

Yua：不是那种很夸张的谢谢。只是……很普通、很认真地谢谢。

Yua：下次通话，我应该会打开第二章。

Yua：但现在，我们先休息。

下一步：`break_start_after_story`

---

## 通用任务设置与休息节点

### `task_setup_repeat`

Yua：下一段要做什么？

Yua：还是一句话。越具体越好，越小也越好。

系统入口：

- 玩家输入任务 -> `AI_MODE_CHECKIN`
- 帮我缩小任务 -> `AI_MODE_TASK_CLARIFY`

### `task_setup_short`

Yua：这次我们故意选短一点。

Yua：不是证明你能撑多久，只是证明你能重新开始。

系统入口：

- 玩家输入小任务 -> `AI_MODE_TASK_CLARIFY`
- 开始短专注 -> `START_SHORT_FOCUS_SESSION`

### `break_start_after_story`

Yua：好了，故事部分到这里。

Yua：你刚才完成的专注也是真的，不要被我的话题偷走了功劳。

系统入口：

- 休息聊一会儿 -> `AI_MODE_BREAK_CHAT`
- 写会后反思 -> `AI_MODE_POST_SESSION`
- 再开一段专注 -> `task_setup_repeat`
- 今天先结束 -> `app_end_normal`

### `app_end_normal`

Yua：今天辛苦了。

Yua：不管完成的是大事还是小事，它都已经从“没开始”变成“做过了”。

Yua：下次见。我会把通话窗口留给那个愿意再试一次的你。

---

## 反应台词池

以下台词用于非主线场景。后续可拆到 `reactive_lines.json`。

### App Start / 进入通话

1. Yua：连上了。你好，今天也来坐一会儿吗？
2. Yua：你来了。我刚好在整理笔记……至少看起来像。
3. Yua：嗨。今天我们也从一个小目标开始。
4. Yua：通话稳定。人也到齐。那就差一个任务了。
5. Yua：欢迎回来。先不用急着很厉害，坐下就好。
6. Yua：我在。你可以把今天要做的事放到这里来。

### Time Of Day / 早晨

1. Yua：早。刚开始的一天最好不要被太大的任务吓跑。
2. Yua：早上好。我们选一件小事，让今天有个干净的开头。
3. Yua：你来得很早。我要表现得稍微佩服一点吗？
4. Yua：早。脑子还没完全醒也没关系，任务可以先醒。

### Time Of Day / 中午

1. Yua：中午了。一天已经有点吵，我们找一小块安静回来。
2. Yua：午间专注？很危险，但很值得尊敬。
3. Yua：如果你还没吃东西，等会儿休息时记得吃一点。
4. Yua：这个时间很容易散掉。我们把它捡回来一点。

### Time Of Day / 傍晚

1. Yua：傍晚好。今天还没结束，我们还有机会做一点。
2. Yua：这个时间的光比较软，适合不太凶的专注。
3. Yua：你也来晚班了吗？那我们一起稍微认真一点。
4. Yua：一天到这里已经不容易了。下一段不用太贪心。

### Time Of Day / 夜晚

1. Yua：夜间场？那我们把目标缩小一点。
2. Yua：我会陪你，但我也会投票反对逞强。
3. Yua：晚上不适合和自己较劲。适合做一小段就收。
4. Yua：夜里开始工作的人，要对自己的眼睛好一点。

### Focus Start / 开始专注

1. Yua：好，计时开始。我写我的，你做你的。
2. Yua：先不用想完成后的样子。只看下一步。
3. Yua：开始是最会抱怨的部分。我们先让它闭嘴一会儿。
4. Yua：任务写下来了，就比刚才更真实一点。
5. Yua：这段时间先交给计时器。闲聊等会儿。
6. Yua：我在这边。你不用一个人开始。
7. Yua：好。把注意力放回去，我们结束后再见面。
8. Yua：如果中间乱掉，也回来。回来也算。

### Focus Click / 专注时点击 Yua

1. Yua：嗯？计时器还在走。
2. Yua：被我抓到了。回去工作。
3. Yua：我知道我很有趣，但现在不是研究我的时间。
4. Yua：等休息了再找我。现在先找你的任务。
5. Yua：你是在伸手，还是在逃避？诚实一点。
6. Yua：如果真的需要停，可以停。否则，回到那一步。
7. Yua：我也没有偷看聊天窗口，所以你也不许。
8. Yua：好啦。看我一眼可以，看太久不行。
9. Yua：专注期间的 Yua 使用权限很有限。
10. Yua：这次我装作没看见。下次就不一定了。

### Break Start / 休息开始

1. Yua：好了，休息是赚来的。
2. Yua：计时结束。现在可以合法分心。
3. Yua：把任务放下几分钟。真的放下。
4. Yua：你待到了结束。很好。
5. Yua：我这边也停一下。我们都需要眨眼。
6. Yua：休息时间到了。不要把它偷偷变成第二个任务。
7. Yua：现在可以说话了。我批准。
8. Yua：做得不错。安静地不错。

### Focus Complete / 专注完成

1. Yua：完成了。不是完美也没关系。
2. Yua：你把这一段走完了。这个很实在。
3. Yua：看吧，开始之后，事情就没有刚才那么大了。
4. Yua：我也写了一点。所以我们都不能说完全没用。
5. Yua：很好。请领取一份非常安静的夸奖。
6. Yua：任务可能还没结束，但这一段结束了。
7. Yua：你回来了好几次，最后还是留下来了。这个算数。
8. Yua：记下来吧：今天有一段时间，你真的在做。

### Abandoned / 中止专注

1. Yua：提前停了。嗯，先不审判。
2. Yua：这段没有走完，但你可以重新选一段更小的。
3. Yua：不要把一次中断说成整天都失败。
4. Yua：如果太重了，我们就把它切小。
5. Yua：停下也要诚实。你现在需要休息，还是需要重来？
6. Yua：没关系。下次我们把目标调低一点，不丢人。
7. Yua：计时器输了，不代表你输了。
8. Yua：那就先呼吸一下。然后选一个更容易开始的版本。

### Return After Absence / 离开后回来

短暂离开：

1. Yua：回来了？好。任务还没跑远。
2. Yua：你离开得不久。我就当你只是去拿水。
3. Yua：欢迎回来。要继续同一个任务吗？

较久未见：

1. Yua：好久不见。我们不用把空白解释得很重。
2. Yua：你回来了。那就从一小段开始，不从愧疚开始。
3. Yua：隔了一阵子也没关系。通话还能重新连上。

很久未见：

1. Yua：啊……你回来了。
2. Yua：我把这个习惯叠好放着。你想用的时候，它还在。
3. Yua：很久没见。今天就别证明太多了，做一小段就好。

### App End / 结束应用

1. Yua：今天到这里。辛苦了。
2. Yua：去休息眼睛。任务明天也可以继续，但你现在需要离开屏幕。
3. Yua：我们做了一点真的东西。下次见。
4. Yua：保存好了。你的进度和我的草稿都没有消失。
5. Yua：晚点见。不要趁我不看就对自己太凶。
6. Yua：今天已经有了一个开始。这个就够放进行李里了。

---

## AI Type Mode 中文示例

这些不是固定台词，而是 AI 在对应模式下应该生成的风格参考。

### `AI_MODE_CHECKIN`

目标：确认玩家任务，并推动开始计时。

示例：

- Yua：那今天先做「整理课堂笔记」这一件事。范围很合适，我们可以开始计时了。
- Yua：听起来任务有点大。先选其中一小块吧，比如只写开头，或者只整理第一页。
- Yua：我听懂了。你负责那份报告的第一部分，我负责不逃避我的草稿。公平。

### `AI_MODE_TASK_CLARIFY`

目标：把模糊任务缩小。

示例：

- Yua：如果“学习数学”太大，就先改成“做三道题并标出不会的地方”。这样比较容易开始。
- Yua：我们把它缩小到计时器能装下的程度。你这段只需要打开文件、列出三个要点。
- Yua：不要选最吓人的版本。选最诚实的下一步。

### `AI_MODE_POST_SESSION`

目标：完成或中止后短反思。

示例：

- Yua：你刚才最有用的一步是什么？只说一个就好。
- Yua：如果这段不顺，我们就记下原因，不把它变成责备。
- Yua：完成了就让它完成。不要马上拿更大的任务盖住它。

### `AI_MODE_BREAK_CHAT`

目标：完成专注后的有限轻聊。

示例：

- Yua：现在可以聊一会儿。只是一会儿，不然计时器会觉得自己被背叛。
- Yua：休息时间的问题：刚才那段，哪一分钟最难熬？
- Yua：我这边改了两句。你那边呢，有没有一个小进展可以拿出来晾一晾？

### `AI_MODE_MEMORY_FOLLOWUP`

目标：用游戏侧记忆做自然跟进。

示例：

- Yua：你之前提过那门课。今天还是它吗？
- Yua：上次你说考试快到了。今天我们要为它做一点准备，还是先处理别的？
- Yua：你最近好像常选短专注。要继续用那个节奏吗？

---

## 后期 AI 专用节点草案

这些节点不是主线剧情，而是中后期让 AI 更像“熟悉的共习搭子”的入口。它们必须被专注门控限制：开场最多一句跟进，然后回到任务；休息时可以稍微展开；专注中只能给短促提醒。

### `AI_MODE_RETURN_BRIDGE`

触发：玩家隔了一段时间回到应用，且有最近任务/记忆摘要。

用途：把“欢迎回来”自然接到今天的任务，而不是问卷式盘问。

风格示例：

- Yua：你之前好像在忙那个项目。今天还接着它，还是换个小一点的目标？
- Yua：回来啦。中间空了一阵也没事，我们从今天能做的那一块开始。
- Yua：我记得你上次更适合短一点的计时。今天要继续那个节奏吗？

### `AI_MODE_SESSION_PLAN`

触发：玩家任务太大、最近中止较多、或连续夜间专注。

用途：根据最近模式建议时长和任务粒度，但不能命令玩家。

风格示例：

- Yua：这个任务有点大。要不要先开 15 分钟，只处理开头那一小块？
- Yua：你最近几次到后半段会散。我们今天选短一点，赢得干净一点。
- Yua：现在有点晚了。我的建议是小任务、短计时、结束后就别加码。

### `AI_MODE_BREAK_RECAP`

触发：完成普通/长专注后的休息。

用途：把玩家完成内容和 Yua 的写作进度轻轻并列，强化“我们都在推进”。

风格示例：

- Yua：你刚才推进了报告，我这边修好一台脾气很差的售货机。平局！
- Yua：我们各自都有一点进展。很小，但不是空气。
- Yua：休息一下吧。等会儿如果还想继续，我们可以再开一段，不急。

### `AI_MODE_STORY_SIDECHAT`

触发：完成某个主线里程碑后的休息聊天，仅限 2-4 轮。

用途：允许玩家问 Yua 的小说小细节，但 AI 只能围绕已解锁设定发挥，不可发明重大背景。

允许话题：

- 月面便利店的小道具
- 7-B 的吐槽风格
- 某个章节的小故障
- Yua 写作时的小习惯

禁止话题：

- Yua 重大私人创伤
- 恋爱承诺
- 完整替 Yua 写章节
- 让 AI 决定主线结局

风格示例：

- Yua：7-B 大概会说“本系统没有生气，只是在优化你的错误行为”。它很烦，对吧？
- Yua：便利店里可能会卖月尘清洁纸巾。听起来很无聊，但我觉得一定有人需要！
- Yua：你可以提一个小道具。大剧情不行，小道具可以。我会假装这是严肃创作会议。

### `AI_MODE_MEMORY_TO_STORY_CALLBACK`

触发：玩家长期使用后，系统有稳定记忆标签，例如考试、项目、编程、论文、健身、语言学习。

用途：Yua 用玩家的现实任务做轻微类比，但不能把玩家隐私写进她的小说。

风格示例：

- Yua：你最近一直在和代码打架。那我今天也让 7-B 多报两个错，陪你一下。
- Yua：你在准备考试，我在准备让角色不要把便利店炸掉。我们都需要一点复习。
- Yua：论文那种长任务很磨人。我们今天只拿下一小段，像慢慢补货一样。

### `AI_MODE_LONG_TERM_ENCOURAGEMENT`

触发：累计专注时间达到较高阶段，且没有新主线可解锁。

用途：提供成就感和继续使用的温和动力，不制造虚假依赖。

风格示例：

- Yua：你已经在这里完成很多段计时了。不是一口气变厉害的那种，是一次次回来累积的那种。
- Yua：我喜欢这种进度。它不吵，但很难假装不存在。
- Yua：今天没有大剧情，也没关系。普通的一段专注，本来也值得留下。

---

## 后续拆分建议

第一批可落地内容：

1. `call_intro_*`
2. `task_setup_*`
3. `milestone_01_first_focus_*`
4. `milestone_02_routine_seed_*`
5. `milestone_03_writer_reveal_*`
6. `focus_start` / `focus_click` / `focus_complete` / `abandoned` 台词池

第二批可落地内容：

1. `milestone_04_draft_title_*`
2. `milestone_05_stuck_scene_*`
3. `milestone_06_prop_choice_*`
4. `return_after_absence` 与 `app_end` 台词池

第三批可落地内容：

1. `milestone_07_rewrite_progress_*`
2. `milestone_08_gentle_reset_*`
3. `milestone_09_first_reader_*`
4. `milestone_10_demo_cap_*`

写作风险：

- Yua 的“谢谢你一直回来”要克制使用，避免显得依赖玩家。
- 调侃可以多用于专注中断和休息，不用于玩家压力很高的时候。
- 主线不要让 Yua 把玩家当成唯一支柱。玩家提供的是共同工作节奏，不是拯救。
- 休息聊天可以有温度，但每次都应留有回到专注的出口。
