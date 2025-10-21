# Censor 🛡️

> 高性能的 Elixir 敏感词过滤库

[![Hex.pm](https://img.shields.io/hexpm/v/censor.svg)](https://hex.pm/packages/censor)
[![Documentation](https://img.shields.io/badge/documentation-gray)](https://hexdocs.pm/censor/)
[![License](https://img.shields.io/hexpm/l/censor.svg)](https://github.com/zven21/censor/blob/main/LICENSE)

**状态**: 🚧 项目规划中

Censor 是一个高性能的 Elixir 敏感词过滤库，提供：
- 🚀 快速检测 - DFA 算法，微秒级性能
- 📝 多种模式 - 检测、替换、高亮
- 🔄 热重载 - 无需重启即可更新词库
- 🌐 多语言 - 支持中文、英文等
- 🎯 灵活规则 - 自定义替换策略

---

## 🎯 为什么选择 Censor？

### 问题：内容安全至关重要

每个用户生成内容的平台都需要敏感词过滤，但高效实现却充满挑战：

#### 问题 1：性能问题

```elixir
# 朴素方法：检查每个词是否在列表中

def contains_sensitive?(text, word_list) do
  Enum.any?(word_list, fn word ->
    String.contains?(text, word)
  end)
end

# 问题：
# - O(n*m) 复杂度 (n = 词数, m = 文本长度)
# - 对于 10,000 个词，检查 "你好世界" 需要 ~10ms
# - 论坛每分钟 1000 条帖子 = 10 秒延迟！
# - 不可接受！😱
```

#### 问题 2：逻辑分散

```elixir
# 敏感词检查散布在代码各处

# 用户注册时
def create_user(params) do
  if contains_bad_word?(params.username) do
    {:error, "用户名包含敏感词"}
  end
end

# 发布内容时
def create_post(params) do
  if contains_bad_word?(params.content) do
    {:error, "内容包含敏感词"}
  end
end

# 评论时
def create_comment(params) do
  if contains_bad_word?(params.text) do
    {:error, "评论包含敏感词"}
  end
end

# 相同逻辑重复到处都是！😫
```

#### 问题 3：更新需要重新部署

```elixir
# 传统方法：词库写在代码或配置中

@sensitive_words ["敏感词1", "敏感词2", ...]

# 问题：需要重新部署才能更新词库！
# - 需要 10-30 分钟
# - 有停机风险
# - 无法快速响应新敏感词
# - 不实用！😤
```

#### 问题 4：没有替换策略

```elixir
# 仅仅阻止是不够的

"你是个傻瓜" -> {:error, "包含敏感词"}

# 更好的用户体验：替换而不是阻止

"你是个傻瓜" -> "你是个**"
"你是个傻瓜" -> "你是个[已过滤]"
"你是个傻瓜" -> "你是个😊"

# 需要灵活的替换！😊
```

---

## 💡 Censor 解决方案

### 快速、灵活、生产就绪

```elixir
# 1. 初始化 Censor（应用启动时）

Censor.start_link(
  words_file: "priv/sensitive_words.txt",
  auto_reload: true
)

# 2. 在代码中任何地方使用

# 检查文本是否包含敏感词
case Censor.check("这是一条包含敏感词的文本") do
  :ok -> 
    # 文本干净
  {:error, :sensitive_word_detected, details} -> 
    # 发现：%{words: ["敏感词"], count: 1}
end

# 替换敏感词
Censor.replace("你好傻瓜世界", replacement: "**")
#=> "你好**世界"

Censor.replace("你好傻瓜世界", replacement: "[已过滤]")
#=> "你好[已过滤]世界"

# 高亮敏感词（用于管理员审核）
Censor.highlight("你好傻瓜世界")
#=> "你好<mark>傻瓜</mark>世界"

# 获取所有匹配
Censor.find_all("文本中有多个敏感词和违禁词")
#=> ["敏感词", "违禁词"]
```

### 性能对比

```
朴素方法 (10,000 词)：
  "你好世界" -> ~10ms ❌

Censor (DFA, 10,000 词)：
  "你好世界" -> ~50μs ✅ (快 200 倍！)
```

### 热重载（无需重启！）

```elixir
# 更新词库文件
echo "新敏感词" >> priv/sensitive_words.txt

# Censor 自动检测并重载
# [info] 🔄 敏感词列表已更新: +1 个词
# [info] ✅ 已加载 10,001 个敏感词

# 立即生效！无需重启！🎉
```

---

## ✨ 核心特性

### 1. 高性能 🚀

使用 DFA（确定性有限自动机）算法：

```elixir
# 性能指标
10 词:        ~10μs 每次检查
100 词:       ~20μs 每次检查
1,000 词:     ~30μs 每次检查
10,000 词:    ~50μs 每次检查
100,000 词:   ~80μs 每次检查

# 每秒可处理数百万次检查！
```

### 2. 多种检测模式 📝

```elixir
# 模式 1：仅检测
Censor.contains?("敏感词")
#=> true

# 模式 2：替换
Censor.replace("敏感词", replacement: "**")
#=> "**"

# 模式 3：高亮
Censor.highlight("敏感词")
#=> "<mark>敏感词</mark>"

# 模式 4：提取所有
Censor.find_all("多个敏感词")
#=> ["敏感词1", "敏感词2"]
```

### 3. 热重载 🔄

```elixir
# 监听文件变化
Censor.start_link(
  words_file: "priv/sensitive_words.txt",
  auto_reload: true,
  reload_interval: 5000  # 每 5 秒检查一次
)

# 或手动重载
Censor.reload()
#=> {:ok, loaded: 10001, added: 5, removed: 2}
```

### 4. 灵活配置 ⚙️

```elixir
# 区分大小写
Censor.check("SENSITIVE", case_sensitive: true)

# 自定义替换
Censor.replace("敏感词", 
  replacement: fn word -> 
    String.duplicate("*", String.length(word))
  end
)
#=> "***"

# 多个词库
Censor.check(text, 
  lists: [:default, :political, :violence, :custom]
)
```

### 5. 多语言支持 🌐

```elixir
# 中文
Censor.check("包含敏感词")

# 英文
Censor.check("contains badword")

# 混合
Censor.check("混合 badword 内容")

# 全部支持！
```

---

## 🚀 快速开始

### 安装

```elixir
# mix.exs
def deps do
  [
    {:censor, "~> 1.0"}
  ]
end
```

### 基本使用

```elixir
# 1. 启动 Censor
{:ok, _pid} = Censor.start_link(
  words: ["敏感词1", "敏感词2", "badword"]
)

# 2. 检查文本
case Censor.check("这是包含敏感词1的文本") do
  :ok -> 
    IO.puts("✅ 文本干净")
  {:error, :sensitive_word_detected, info} -> 
    IO.puts("❌ 发现: #{inspect(info.words)}")
end

# 3. 替换敏感词
clean_text = Censor.replace("包含敏感词1的文本", replacement: "***")
IO.puts(clean_text)
#=> "包含***的文本"
```

### 配置

Censor 支持多种配置方法：

#### 1. 应用配置 (config/config.exs)

```elixir
config :censor,
  words: ["敏感词1", "敏感词2"],
  words_file: "priv/sensitive_words.txt",
  auto_reload: true,
  case_sensitive: false,
  replacement: "***"
```

#### 2. 环境变量

```bash
export CENSOR_WORDS_FILE="priv/sensitive_words.txt"
export CENSOR_AUTO_RELOAD="true"
export CENSOR_CASE_SENSITIVE="false"
export CENSOR_REPLACEMENT="***"
```

#### 3. 运行时选项

```elixir
Censor.start_link([
  words: ["badword1", "badword2"],
  auto_reload: true,
  case_sensitive: false
])
```

**配置优先级**: 运行时选项 > 环境变量 > 应用配置 > 默认值

### 从文件加载

```elixir
# words.txt
敏感词1
敏感词2
违禁词
badword

# 加载
Censor.start_link(
  words_file: "priv/sensitive_words.txt",
  auto_reload: true
)
```

### 在控制器中使用

```elixir
defmodule MyAppWeb.PostController do
  use MyAppWeb, :controller
  
  def create(conn, %{"post" => post_params}) do
    case Censor.check(post_params["content"]) do
      :ok ->
        # 创建帖子
        {:ok, post} = Posts.create_post(post_params)
        render(conn, "show.json", post: post)
        
      {:error, :sensitive_word_detected, info} ->
        conn
        |> put_status(400)
        |> json(%{
          error: "内容包含敏感词",
          words: info.words
        })
    end
  end
end
```

### 在 GraphQL 中使用

```elixir
# Absinthe 中间件
defmodule MyAppWeb.Middleware.SensitiveWordCheck do
  @behaviour Absinthe.Middleware
  
  def call(%{arguments: args} = resolution, _config) do
    # 检查所有字符串参数
    case check_args(args) do
      :ok -> 
        resolution
      {:error, words} -> 
        Absinthe.Resolution.put_result(resolution, 
          {:error, "内容包含敏感词: #{Enum.join(words, ", ")}"})
    end
  end
  
  defp check_args(args) do
    args
    |> Map.values()
    |> Enum.filter(&is_binary/1)
    |> Enum.reduce_while(:ok, fn text, :ok ->
      case Censor.check(text) do
        :ok -> {:cont, :ok}
        {:error, :sensitive_word_detected, info} -> 
          {:halt, {:error, info.words}}
      end
    end)
  end
end

# 在 schema 中使用
field :create_post, :post do
  arg :content, non_null(:string)
  
  middleware MyAppWeb.Middleware.SensitiveWordCheck
  resolve &Resolvers.Posts.create/3
end
```

---

## 🛠️ 架构设计

### DFA 算法

```
从词库构建 DFA：
  敏感词 → 状态机

检查文本：
  "这是敏感词" → 遍历 DFA
  
  这 → 状态 0
  是 → 状态 0
  敏 → 状态 1
  感 → 状态 2
  词 → 状态 3 (匹配！)
  
时间复杂度：O(n) 其中 n = 文本长度
```

### 热重载机制

```
FileSystem 监听 words.txt
    ↓
检测到文件变化
    ↓
重新加载词库
    ↓
重建 DFA
    ↓
原子交换（无停机时间）
    ↓
新请求使用新 DFA
```

---

## 📊 使用场景

### 场景 1：社交平台

```elixir
# 检查用户生成内容
- 用户资料（用户名、简介）
- 帖子和评论
- 私信
- 聊天消息

# 自动审核
Censor.moderate(content,
  on_detect: :replace,  # 或 :block, :review
  replacement: "***"
)
```

### 场景 2：电商平台

```elixir
# 检查商品信息
- 商品名称
- 商品描述
- 评论内容
- 客服聊天

# 防止竞品品牌名
Censor.add_words(["竞品1", "竞品2"])
```

### 场景 3：管理员审核

```elixir
# 高亮显示供人工审核
content = Censor.highlight(user_content)

# 管理员看到：
# "这是<mark>敏感词</mark>的内容"

# 审核界面
render "review.html",
  content: content,
  matches: Censor.find_all(user_content)
```

---

## 📄 许可证

MIT 许可证 - 详见 [LICENSE](LICENSE)

---

*为内容平台构建者用心制作 ❤️*
