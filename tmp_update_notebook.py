import json

filepath = r'c:\Users\Administrator\AndroidStudioProjects\ai-engine\train_phobert.ipynb'

with open(filepath, 'r', encoding='utf-8') as f:
    nb = json.load(f)

# Update compute_metrics cell
nb['cells'][7]['source'] = [
    "import torch\n",
    "from torch import nn\n",
    "from transformers import TrainingArguments, Trainer\n",
    "import evaluate\n",
    "import numpy as np\n",
    "\n",
    "accuracy = evaluate.load('accuracy')\n",
    "f1_metric = evaluate.load('f1')\n",
    "precision_metric = evaluate.load('precision')\n",
    "recall_metric = evaluate.load('recall')\n",
    "\n",
    "def compute_metrics(eval_pred):\n",
    "    predictions, labels = eval_pred\n",
    "    predictions = np.argmax(predictions, axis=1)\n",
    "    acc = accuracy.compute(predictions=predictions, references=labels)\n",
    "    f1 = f1_metric.compute(predictions=predictions, references=labels, average='macro')\n",
    "    precision = precision_metric.compute(predictions=predictions, references=labels, average='macro')\n",
    "    recall = recall_metric.compute(predictions=predictions, references=labels, average='macro')\n",
    "    return {\n",
    "        'accuracy': acc['accuracy'],\n",
    "        'f1_macro': f1['f1'],\n",
    "        'precision_macro': precision['precision'],\n",
    "        'recall_macro': recall['recall']\n",
    "    }\n",
    "\n",
    "training_args = TrainingArguments(\n",
    "    output_dir='./phobert-generic-classifier',\n",
    "    eval_strategy='epoch',\n",
    "    save_strategy='epoch',\n",
    "    learning_rate=2e-5,\n",
    "    per_device_train_batch_size=16,\n",
    "    per_device_eval_batch_size=16,\n",
    "    num_train_epochs=10,\n",
    "    weight_decay=0.01,\n",
    "    load_best_model_at_end=True,\n",
    "    metric_for_best_model='f1_macro',\n",
    "    logging_steps=10,\n",
    "    push_to_hub=False,\n",
    ")\n",
    "\n",
    "class CustomTrainer(Trainer):\n",
    "    def compute_loss(self, model, inputs, return_outputs=False, **kwargs):\n",
    "        labels = inputs.get('labels')\n",
    "        outputs = model(**inputs)\n",
    "        logits = outputs.get('logits')\n",
    "        \n",
    "        weights = torch.tensor(class_weights, dtype=torch.float32).to(model.device)\n",
    "        loss_fct = nn.CrossEntropyLoss(weight=weights)\n",
    "        loss = loss_fct(logits.view(-1, self.model.config.num_labels), labels.view(-1))\n",
    "        return (loss, outputs) if return_outputs else loss\n",
    "\n",
    "trainer = CustomTrainer(\n",
    "    model=model,\n",
    "    args=training_args,\n",
    "    train_dataset=train_dataset,\n",
    "    eval_dataset=test_dataset,\n",
    "    processing_class=tokenizer,\n",
    "    compute_metrics=compute_metrics,\n",
    ")\n",
    "\n",
    "print(' Custom Trainer with Class Weights configured')\n"
]

# Update evaluation print cell
nb['cells'][9]['source'] = [
    "results = trainer.evaluate()\n",
    "print(f'\\n Evaluation Results:')\n",
    "print(f'  Accuracy: {results[\"eval_accuracy\"]:.2%}')\n",
    "val1 = results.get(\"eval_precision_macro\", 0)\n",
    "print(f'  Precision Macro: {val1:.2%}')\n",
    "val2 = results.get(\"eval_recall_macro\", 0)\n",
    "print(f'  Recall Macro: {val2:.2%}')\n",
    "val3 = results.get(\"eval_f1_macro\", 0)\n",
    "print(f'  F1 Macro: {val3:.2%}')\n",
    "print(f'  Loss: {results[\"eval_loss\"]:.4f}')\n"
]

with open(filepath, 'w', encoding='utf-8') as f:
    json.dump(nb, f, ensure_ascii=False, indent=2)
