# Translation store for MetaPrepR (English primary, Portuguese optional).
#
# English is the default and the fallback for any missing key. Language is
# chosen once per session via a `?lang=pt` query parameter (see app_ui.R's
# get_lang()) and does not change reactively - switching language is a full
# page reload, which keeps this file a plain data structure with no Shiny
# reactivity of its own.
#
# Five things live here:
#   tool_slugs      - stable, never-translated identifiers for each tool
#                     (also used as the Tool column in the workspace, in the
#                     CSV/XLSX exports, and as the GA4 event parameter)
#   ui_text         - static app strings (nav titles, headers, help text,
#                     labels, button text)
#   field_labels    - short names for calculator inputs, used inside
#                     validation error messages (e.g. "se" -> "SE" / "EP")
#   scenario_labels - display labels for the internal S1/S2/S3 scenario
#                     codes (the codes themselves are never translated -
#                     they are matched literally in calc_median_to_mean_sd.R)
#   messages        - functions (not templates) that build the final
#                     validation/error text for each message code returned
#                     by the calc_*.R functions; one function per language so
#                     each can use its own word order and grammar

# Stable tool identifiers. These are deliberately language-independent and
# must stay unchanged once published: they end up in exported datasets that
# users cite, and in the analytics event stream, so renaming one silently
# breaks both. Keyed by the input prefix used in the UI.
tool_slugs <- c(
  se    = "se-to-sd",
  ci    = "95ci-to-sd",
  iqr   = "iqr-to-sd",
  med   = "median-to-mean",
  sdc   = "sd-change-imput",
  comb  = "combine-group",
  split = "split-group"
)

#' Look up a tool's stable slug from its UI prefix
tool_slug <- function(prefix) {
  v <- tool_slugs[[prefix]]
  if (is.null(v)) prefix else v
}

ui_text <- list(
  en = list(
    app_title = "MetaPrepR",
    app_subtitle = "Meta-Analysis Preparation in R",
    app_tagline = "Continuous-outcome data preparation",

    nav_home = "Home",
    nav_variance = "Variance conversions",
    nav_estimation = "Estimation & imputation",
    nav_groups = "Group manipulation",
    nav_workspace = "Workspace",
    nav_notes = "Notes",

    nav_se = "SE -> SD",
    nav_ci = "95% CI -> SD",
    nav_iqr = "IQR -> SD",
    nav_median = "Median -> mean & SD",
    nav_sdchange = "SD of change",
    nav_combine = "Combine groups",
    nav_split = "Split shared control",

    # -- Home --------------------------------------------------------------
    home_title = "Prepare continuous-outcome data for meta-analysis",
    home_lede = paste(
      "Calculate or estimate the mean, standard deviation, and sample size a study",
      "never reported directly, working from standard errors, confidence intervals,",
      "medians, or quartiles, following the Cochrane Handbook and the primary",
      "literature on estimating means and SDs from summary statistics."
    ),
    home_tools_label = "Tools",

    home_desc_se = "Convert a standard error into a standard deviation.",
    home_desc_ci = "Recover the SD from a 95% confidence interval, using t or z.",
    home_desc_iqr = "Estimate the SD from an interquartile range.",
    home_desc_median = "Estimate mean and SD from a median with a range or quartiles (Wan, Hozo, or Luo).",
    home_desc_sdchange = "Impute the SD of change-from-baseline scores, with a sensitivity readout.",
    home_desc_combine = "Pool two or more arms into one weighted mean and SD.",
    home_desc_split = "Divide a shared control group across several comparisons.",
    home_desc_workspace = "Collect every result, then export to CSV or XLSX.",
    home_desc_notes = "The methodological approach behind each tool, the licence, how to cite it, and the main references.",

    ref_cochrane = "Higgins JPT, Thomas J, Chandler J, et al., editors. Cochrane Handbook for Systematic Reviews of Interventions. Version 6.5. Cochrane; 2024.",
    ref_hozo = "Hozo SP, Djulbegovic B, Hozo I. Estimating the mean and variance from the median, range, and the size of a sample. BMC Med Res Methodol. 2005;5:13.",
    ref_wan = "Wan X, Wang W, Liu J, Tong T. Estimating the sample mean and standard deviation from the sample size, median, range and/or interquartile range. BMC Med Res Methodol. 2014;14:135.",
    ref_luo = "Luo D, Wan X, Liu J, Tong T. Optimally estimating the sample mean from the sample size, median, mid-range, and/or mid-quartile range. Stat Methods Med Res. 2018;27(6):1785-1805.",

    # -- Sidebar ------------------------------------------------------------
    sidebar_language = "Language",
    sidebar_ws_preview = "Workspace preview",
    sidebar_ws_empty = "No data yet. Send a result from any tool.",
    sidebar_ws_rows = "Rows in workspace:",

    # -- Cards and help ------------------------------------------------------
    card_se = "Standard error to standard deviation",
    card_ci = "95% confidence interval (of a mean) to standard deviation",
    card_iqr = "Interquartile range to standard deviation",
    card_median = "Median, range, or IQR to mean and standard deviation",
    card_sdchange = "Standard deviation of change from baseline",
    card_combine = "Combine k >= 2 groups (Cochrane Handbook Table 6.5.a)",
    card_split = "Split a shared control group across k comparisons",
    card_workspace = "Workspace",
    card_notes = "Notes",
    card_result = "Result",

    help_se = "SD = SE times the square root of n. Cochrane Handbook 6.5.2.2.",
    help_ci = "Assumes a symmetric 95% CI for a mean. SE = (upper - lower) / (2 times the critical value); SD = SE times the square root of n.",
    help_iqr = "SD = (Q3 - Q1) / 1.35 (normal approximation).",
    help_sdchange = "SD_change = square root of (SD_base^2 + SD_final^2 - 2 * r * SD_base * SD_final)",
    help_combine = "Set how many groups you are combining, then enter each one. The result updates as you type.",
    help_split = "The control N is divided into k whole parts that add back up to it exactly; mean and SD stay unchanged.",
    help_workspace = "Results sent from any calculator land here. Edit the table directly if needed.",

    help_hozo_fields = "Hozo needs minimum, median, maximum, and n (S1 only). The SD formula switches at n <= 15, n <= 70, and n > 70; the mean uses the full range formula for n <= 25, and the median alone above that.",
    help_wanluo_fields = "Wan and Luo support three scenarios. Fill in what your source reports: minimum, median, maximum (S1); Q1, median, Q3 (S2); or all five (S3). Leave the rest blank.",

    alert_ci = "The t and z critical values diverge for small n. Using z when n is small understates SD. Prefer t unless there is a specific reason to use z.",
    alert_iqr = "This assumes approximate normality. When the sample size is known, the Wan (2014) method under estimation & imputation is preferable.",
    alert_sdchange = "Cochrane's default imputation is r = 0.5 when the true correlation is unknown.",
    alert_combine_sd = "SD is optional. Leave every SD blank and you still get the combined N and mean, which need only N and mean. The pooled SD requires an SD for every group: if even one is missing it is not reported, because a variance pooled from part of the groups would not describe the combined group.",
    alert_split = "This is the simple Cochrane approximation for avoiding double-counting a shared control group. For a rigorous alternative, use network or multivariate meta-analysis.",

    # -- Input labels --------------------------------------------------------
    lbl_se = "Standard error (SE):",
    lbl_n = "Sample size (n):",
    lbl_lower = "Lower bound:",
    lbl_upper = "Upper bound:",
    lbl_q1 = "Q1 (first quartile):",
    lbl_q3 = "Q3 (third quartile):",
    lbl_min = "Minimum:",
    lbl_median = "Median:",
    lbl_max = "Maximum:",
    lbl_sd_base = "SD at baseline:",
    lbl_sd_final = "SD at final measurement:",
    lbl_r = "Assumed correlation r:",
    lbl_split_n = "Control group N:",
    lbl_split_k = "Number of comparisons (k):",
    lbl_split_mean = "Control group mean (optional):",
    lbl_split_sd = "Control group SD (optional):",
    lbl_split_weighting = "How to divide the control N:",
    choice_split_even = "Equally (Cochrane default)",
    choice_split_proportional = "In proportion to intervention arm sizes",
    lbl_split_arm_n = "Intervention arm sizes, comma-separated (one per comparison):",
    lbl_study_id = "Study ID (optional):",
    lbl_group_label = "Group label (optional):",
    lbl_group_prefix = "Group label prefix (optional):",
    lbl_mean_optional = "Mean (optional, for the workspace):",
    lbl_n_optional = "Sample size (n, optional for the workspace):",
    lbl_comb_k = "How many groups are you combining?",
    lbl_comb_group = "Group %d",

    lbl_crit_method = "Critical value:",
    choice_t = "t distribution (exact, recommended)",
    choice_z = "Normal approximation (z = 1.96)",

    lbl_method = "Method:",
    choice_wan = "Wan (2014), default",
    choice_hozo = "Hozo (2005), range only",
    choice_luo = "Luo (2018) mean with Wan (2014) SD",

    # -- Buttons and messages -------------------------------------------------
    btn_send = "Send to workspace",
    btn_send_split = "Send all k rows to workspace",
    btn_download_csv = "Download CSV",
    btn_download_xlsx = "Download XLSX",
    btn_clear = "Clear table",
    btn_cancel = "Cancel",
    btn_delete = "Delete",

    modal_clear_title = "Confirm deletion",
    modal_clear_body = "Delete all %d record(s) from the workspace? This cannot be undone.",
    msg_sent = "Result sent to the workspace.",
    msg_sent_split = "%d rows sent to the workspace.",
    msg_cleared = "Workspace cleared.",

    lang_toggle_to_pt = "Português",
    lang_toggle_to_en = "English",

    result_awaiting = "Enter valid values above to see the result.",
    result_error_prefix = "Cannot calculate:",
    result_not_provided = "not provided",
    result_sensitivity_header = "Sensitivity:",
    result_sd_change_undefined = "undefined (negative under square root)",
    result_scenario_label = "Scenario",
    result_crit_label = "Critical value used",
    result_label_sd = "SD",
    result_label_mean = "Mean",
    result_label_n = "N",
    result_label_n_per_comparison = "N per comparison",
    result_label_n_total = "Total allocated",
    result_label_mean_sd_slash = "Mean/SD",
    result_sd_unavailable = "not calculated (an SD is missing)",

    method_se = "SE -> SD",
    method_iqr = "IQR -> SD",
    method_hozo = "Hozo (2005)",
    method_wan = "Wan (2014)",
    method_luo = "Luo (2018) + Wan (2014)",
    method_combine = "Combined groups",
    method_combine_no_sd = "Combined groups (N and mean only)",
    method_split = "Split control",

    col_study_id = "Study ID",
    col_group_label = "Group label",
    col_tool = "Tool",
    col_method = "Method",
    col_mean = "Mean",
    col_sd = "SD",
    col_sd_optional = "SD (optional)",
    col_n = "N",

    # -- Notes ----------------------------------------------------------------
    notes_technical_label = "What the app does",
    notes_technical = paste(
      "MetaPrepR converts the summary statistics trials actually report into the",
      "mean, standard deviation, and sample size that inverse-variance meta-analysis",
      "requires. It implements SD recovery from a standard error or a symmetric 95%",
      "confidence interval (Cochrane Handbook 6.5.2.2, with a selectable t or z",
      "critical value), the normal-approximation SD from an interquartile range",
      "(6.5.2.5), mean and SD estimation from a median reported with a range, with",
      "quartiles, or with both (Hozo 2005; Wan 2014; Luo 2018, across scenarios",
      "S1-S3), imputation of the SD of change from baseline with a user-set",
      "correlation and a sensitivity readout at r = 0.3/0.5/0.7 (6.5.2.8),",
      "combination of k >= 2 arms into a single weighted mean and pooled SD",
      "(Table 6.5.a), and splitting of a shared control group across k comparisons",
      "(6.5.2.10). Every result carries its tool slug and method label into the",
      "workspace, so the provenance of each row survives export."
    ),

    notes_plain_label = "In plain language",
    notes_plain = paste(
      "Meta-analysis needs each study to report an average, a measure of spread",
      "(the standard deviation), and how many people were studied. Many papers",
      "report something else: a middle value, a range, or an error bar. Throwing",
      "those studies away biases the review; guessing at the numbers is worse.",
      "This app applies the standard published formulas that translate what a paper",
      "did report into what the analysis needs, shows the result immediately, and",
      "keeps a record of which formula produced each number so a reader or reviewer",
      "can check the work later."
    ),

    notes_repo_label = "Source code",
    notes_repo_text = "Issues and pull requests are welcome.",
    notes_licence_label = "Licence",
    notes_licence_text = paste(
      "MIT licence, copyright Daniel Umpierre. You may use, modify, and redistribute",
      "the software, including commercially, provided the copyright notice and licence",
      "text are kept. It is provided without warranty: you remain responsible for",
      "checking that a given estimate is appropriate for your data."
    ),
    notes_citation_label = "How to cite",
    notes_citation_software = "Umpierre D. MetaPrepR: Meta-Analysis Preparation in R [software]. 2026. Available from: https://github.com/dumpierre/metaprepr",
    notes_citation_note = "Also cite the primary method you used (listed under References on the Home page), not only this software.",
    notes_preprint_label = "Methodological preprint",
    notes_preprint_text = "A methods paper describing the tool and its validation is in preparation. This entry will be replaced with the preprint DOI once it is posted.",

    notes_refs_label = "References",
    notes_refs_intro = "The sources the calculators implement. Cite the one your estimate came from, not only this software.",

    # -- Analytics consent ------------------------------------------------------
    consent_text = "This site uses Google Analytics (with IP anonymization) to count visits and understand usage. No personally identifying data is collected.",
    btn_accept = "Accept",
    btn_decline = "Decline"
  ),

  pt = list(
    app_title = "MetaPrepR",
    app_subtitle = "Preparação de Dados para Metanálise em R",
    app_tagline = "Preparação de dados de desfechos contínuos",

    nav_home = "Início",
    nav_variance = "Conversões de variância",
    nav_estimation = "Estimativa e imputação",
    nav_groups = "Manipulação de grupos",
    nav_workspace = "Área de trabalho",
    nav_notes = "Notas",

    nav_se = "EP -> DP",
    nav_ci = "IC 95% -> DP",
    nav_iqr = "IQR -> DP",
    nav_median = "Mediana -> média e DP",
    nav_sdchange = "DP da mudança",
    nav_combine = "Combinar grupos",
    nav_split = "Dividir controle compartilhado",

    # -- Início ---------------------------------------------------------------
    home_title = "Prepare dados de desfechos contínuos para metanálise",
    home_lede = paste(
      "Calcule ou estime a média, o desvio padrão e o tamanho da amostra que um estudo",
      "não relatou diretamente, a partir de erros padrão, intervalos de confiança,",
      "medianas ou quartis, seguindo o Manual Cochrane e a literatura primária sobre",
      "estimativa de médias e DPs a partir de estatísticas resumidas."
    ),
    home_tools_label = "Ferramentas",

    home_desc_se = "Converta um erro padrão em desvio padrão.",
    home_desc_ci = "Recupere o DP a partir de um intervalo de confiança de 95%, usando t ou z.",
    home_desc_iqr = "Estime o DP a partir de um intervalo interquartil.",
    home_desc_median = "Estime média e DP a partir de uma mediana com amplitude ou quartis (Wan, Hozo ou Luo).",
    home_desc_sdchange = "Impute o DP dos escores de mudança, com análise de sensibilidade.",
    home_desc_combine = "Agrupe dois ou mais braços em uma única média ponderada e DP.",
    home_desc_split = "Divida um grupo controle compartilhado entre várias comparações.",
    home_desc_workspace = "Reúna todos os resultados e exporte para CSV ou XLSX.",
    home_desc_notes = "A abordagem metodológica de cada ferramenta, a licença, como citar e as principais referências.",

    ref_cochrane = "Higgins JPT, Thomas J, Chandler J, et al., editores. Cochrane Handbook for Systematic Reviews of Interventions. Versão 6.5. Cochrane; 2024.",
    ref_hozo = "Hozo SP, Djulbegovic B, Hozo I. Estimating the mean and variance from the median, range, and the size of a sample. BMC Med Res Methodol. 2005;5:13.",
    ref_wan = "Wan X, Wang W, Liu J, Tong T. Estimating the sample mean and standard deviation from the sample size, median, range and/or interquartile range. BMC Med Res Methodol. 2014;14:135.",
    ref_luo = "Luo D, Wan X, Liu J, Tong T. Optimally estimating the sample mean from the sample size, median, mid-range, and/or mid-quartile range. Stat Methods Med Res. 2018;27(6):1785-1805.",

    # -- Barra lateral ----------------------------------------------------------
    sidebar_language = "Idioma",
    sidebar_ws_preview = "Prévia da área de trabalho",
    sidebar_ws_empty = "Nenhum dado ainda. Envie um resultado de qualquer ferramenta.",
    sidebar_ws_rows = "Linhas na área de trabalho:",

    # -- Cartões e ajuda ---------------------------------------------------------
    card_se = "Erro padrão para desvio padrão",
    card_ci = "Intervalo de confiança de 95% (de uma média) para desvio padrão",
    card_iqr = "Intervalo interquartil para desvio padrão",
    card_median = "Mediana, amplitude ou IQR para média e desvio padrão",
    card_sdchange = "Desvio padrão da mudança em relação à linha de base",
    card_combine = "Combinar k >= 2 grupos (Manual Cochrane, Tabela 6.5.a)",
    card_split = "Dividir um grupo controle compartilhado entre k comparações",
    card_workspace = "Área de trabalho",
    card_notes = "Notas",
    card_result = "Resultado",

    help_se = "DP = EP vezes a raiz quadrada de n. Manual Cochrane 6.5.2.2.",
    help_ci = "Pressupõe um IC 95% simétrico para uma média. EP = (limite superior - limite inferior) / (2 vezes o valor crítico); DP = EP vezes a raiz quadrada de n.",
    help_iqr = "DP = (Q3 - Q1) / 1,35 (aproximação normal).",
    help_sdchange = "DP_mudança = raiz quadrada de (DP_base^2 + DP_final^2 - 2 * r * DP_base * DP_final)",
    help_combine = "Defina quantos grupos você está combinando e informe cada um deles. O resultado é atualizado enquanto você digita.",
    help_split = "O N do controle é dividido em k partes inteiras que somam exatamente esse total; média e DP permanecem inalterados.",
    help_workspace = "Os resultados enviados de qualquer calculadora aparecem aqui. Edite a tabela diretamente, se necessário.",

    help_hozo_fields = "Hozo exige mínimo, mediana, máximo e n (apenas S1). A fórmula do DP muda em n <= 15, n <= 70 e n > 70; a média usa a fórmula completa da amplitude para n <= 25 e a mediana isolada acima disso.",
    help_wanluo_fields = "Wan e Luo aceitam três cenários. Preencha o que sua fonte relatar: mínimo, mediana, máximo (S1); Q1, mediana, Q3 (S2); ou os cinco valores (S3). Deixe o restante em branco.",

    alert_ci = "Os valores críticos t e z divergem para n pequeno. Usar z quando n é pequeno subestima o DP. Prefira t, a menos que haja um motivo específico para usar z.",
    alert_iqr = "Isso pressupõe normalidade aproximada. Quando o tamanho da amostra é conhecido, o método de Wan (2014), em estimativa e imputação, é preferível.",
    alert_sdchange = "A imputação padrão do Cochrane é r = 0,5 quando a correlação verdadeira é desconhecida.",
    alert_combine_sd = "O DP é opcional. Deixe todos os DPs em branco e você ainda obtém o N e a média combinados, que dependem apenas de N e média. O DP agrupado exige um DP para cada grupo: se faltar um único, ele não é informado, porque uma variância agrupada a partir de apenas parte dos grupos não descreveria o grupo combinado.",
    alert_split = "Esta é a aproximação simples do Cochrane para evitar a dupla contagem de um grupo controle compartilhado. Para uma alternativa rigorosa, use metanálise em rede ou multivariada.",

    # -- Rótulos de entrada -------------------------------------------------------
    lbl_se = "Erro padrão (EP):",
    lbl_n = "Tamanho da amostra (n):",
    lbl_lower = "Limite inferior:",
    lbl_upper = "Limite superior:",
    lbl_q1 = "Q1 (primeiro quartil):",
    lbl_q3 = "Q3 (terceiro quartil):",
    lbl_min = "Mínimo:",
    lbl_median = "Mediana:",
    lbl_max = "Máximo:",
    lbl_sd_base = "DP na linha de base:",
    lbl_sd_final = "DP na medida final:",
    lbl_r = "Correlação assumida r:",
    lbl_split_n = "N do grupo controle:",
    lbl_split_k = "Número de comparações (k):",
    lbl_split_mean = "Média do grupo controle (opcional):",
    lbl_split_sd = "DP do grupo controle (opcional):",
    lbl_split_weighting = "Como dividir o N do controle:",
    choice_split_even = "Igualmente (padrão Cochrane)",
    choice_split_proportional = "Proporcionalmente ao tamanho dos braços de intervenção",
    lbl_split_arm_n = "Tamanhos dos braços de intervenção, separados por vírgula (um por comparação):",
    lbl_study_id = "ID do estudo (opcional):",
    lbl_group_label = "Rótulo do grupo (opcional):",
    lbl_group_prefix = "Prefixo do rótulo do grupo (opcional):",
    lbl_mean_optional = "Média (opcional, para a área de trabalho):",
    lbl_n_optional = "Tamanho da amostra (n, opcional para a área de trabalho):",
    lbl_comb_k = "Quantos grupos você está combinando?",
    lbl_comb_group = "Grupo %d",

    lbl_crit_method = "Valor crítico:",
    choice_t = "distribuição t (exata, recomendada)",
    choice_z = "aproximação normal (z = 1,96)",

    lbl_method = "Método:",
    choice_wan = "Wan (2014), padrão",
    choice_hozo = "Hozo (2005), apenas amplitude",
    choice_luo = "Média de Luo (2018) com DP de Wan (2014)",

    # -- Botões e mensagens ---------------------------------------------------------
    btn_send = "Enviar para a área de trabalho",
    btn_send_split = "Enviar todas as k linhas para a área de trabalho",
    btn_download_csv = "Baixar CSV",
    btn_download_xlsx = "Baixar XLSX",
    btn_clear = "Limpar tabela",
    btn_cancel = "Cancelar",
    btn_delete = "Excluir",

    modal_clear_title = "Confirmar exclusão",
    modal_clear_body = "Excluir todos os %d registro(s) da área de trabalho? Esta ação não pode ser desfeita.",
    msg_sent = "Resultado enviado para a área de trabalho.",
    msg_sent_split = "%d linhas enviadas para a área de trabalho.",
    msg_cleared = "Área de trabalho limpa.",

    lang_toggle_to_pt = "Português",
    lang_toggle_to_en = "English",

    result_awaiting = "Informe valores válidos acima para ver o resultado.",
    result_error_prefix = "Não é possível calcular:",
    result_not_provided = "não informado",
    result_sensitivity_header = "Sensibilidade:",
    result_sd_change_undefined = "indefinido (negativo sob a raiz quadrada)",
    result_scenario_label = "Cenário",
    result_crit_label = "Valor crítico utilizado",
    result_label_sd = "DP",
    result_label_mean = "Média",
    result_label_n = "N",
    result_label_n_per_comparison = "N por comparação",
    result_label_n_total = "Total alocado",
    result_label_mean_sd_slash = "Média/DP",
    result_sd_unavailable = "não calculado (falta um DP)",

    method_se = "EP -> DP",
    method_iqr = "IQR -> DP",
    method_hozo = "Hozo (2005)",
    method_wan = "Wan (2014)",
    method_luo = "Luo (2018) + Wan (2014)",
    method_combine = "Grupos combinados",
    method_combine_no_sd = "Grupos combinados (apenas N e média)",
    method_split = "Controle dividido",

    col_study_id = "ID do estudo",
    col_group_label = "Rótulo do grupo",
    col_tool = "Ferramenta",
    col_method = "Método",
    col_mean = "Média",
    col_sd = "DP",
    col_sd_optional = "DP (opcional)",
    col_n = "N",

    # -- Notas ------------------------------------------------------------------
    notes_technical_label = "O que o aplicativo faz",
    notes_technical = paste(
      "O MetaPrepR converte as estatísticas resumidas que os ensaios de fato relatam",
      "na média, no desvio padrão e no tamanho de amostra exigidos pela metanálise de",
      "variância inversa. Implementa a recuperação do DP a partir de um erro padrão ou",
      "de um IC 95% simétrico (Manual Cochrane 6.5.2.2, com valor crítico t ou z",
      "selecionável), o DP por aproximação normal a partir do intervalo interquartil",
      "(6.5.2.5), a estimativa de média e DP a partir de uma mediana relatada com",
      "amplitude, com quartis ou com ambos (Hozo 2005; Wan 2014; Luo 2018, nos cenários",
      "S1-S3), a imputação do DP da mudança em relação à linha de base com correlação",
      "definida pelo usuário e análise de sensibilidade em r = 0,3/0,5/0,7 (6.5.2.8), a",
      "combinação de k >= 2 braços em uma única média ponderada e DP agrupado",
      "(Tabela 6.5.a) e a divisão de um grupo controle compartilhado entre k comparações",
      "(6.5.2.10). Cada resultado leva seu identificador de ferramenta e o rótulo do",
      "método para a área de trabalho, de modo que a procedência de cada linha",
      "sobrevive à exportação."
    ),

    notes_plain_label = "Em linguagem simples",
    notes_plain = paste(
      "A metanálise precisa que cada estudo informe uma média, uma medida de dispersão",
      "(o desvio padrão) e quantas pessoas foram estudadas. Muitos artigos relatam",
      "outra coisa: um valor central, uma amplitude ou uma barra de erro. Descartar",
      "esses estudos enviesa a revisão; chutar os números é pior. Este aplicativo",
      "aplica as fórmulas publicadas que traduzem o que o artigo relatou naquilo de que",
      "a análise precisa, mostra o resultado imediatamente e registra qual fórmula gerou",
      "cada número, para que um leitor ou revisor possa conferir o trabalho depois."
    ),

    notes_repo_label = "Código-fonte",
    notes_repo_text = "Issues e pull requests são bem-vindos.",
    notes_licence_label = "Licença",
    notes_licence_text = paste(
      "Licença MIT, direitos autorais de Daniel Umpierre. Você pode usar, modificar e",
      "redistribuir o software, inclusive comercialmente, desde que o aviso de direitos",
      "autorais e o texto da licença sejam mantidos. É fornecido sem garantia: a",
      "responsabilidade de verificar se uma estimativa é adequada aos seus dados",
      "continua sendo sua."
    ),
    notes_citation_label = "Como citar",
    notes_citation_software = "Umpierre D. MetaPrepR: Meta-Analysis Preparation in R [software]. 2026. Disponível em: https://github.com/dumpierre/metaprepr",
    notes_citation_note = "Cite também o método primário utilizado (listado em Referências, na página inicial), não apenas este software.",
    notes_preprint_label = "Preprint metodológico",
    notes_preprint_text = "Um artigo metodológico descrevendo a ferramenta e sua validação está em preparação. Esta entrada será substituída pelo DOI do preprint assim que ele for publicado.",

    notes_refs_label = "Referências",
    notes_refs_intro = "As fontes que as calculadoras implementam. Cite aquela de onde veio a sua estimativa, não apenas este software.",

    # -- Consentimento de análise ------------------------------------------------
    consent_text = "Este site usa o Google Analytics (com anonimização de IP) para contar visitas e entender o uso. Nenhum dado de identificação pessoal é coletado.",
    btn_accept = "Aceitar",
    btn_decline = "Recusar"
  )
)

field_labels <- list(
  en = list(
    se = "SE", n = "n", lower_bound = "lower bound", upper_bound = "upper bound",
    q1 = "Q1", q3 = "Q3", min_val = "minimum", med_val = "median", max_val = "maximum",
    sd_base = "SD at baseline", sd_final = "SD at final measurement", r = "correlation r",
    n1 = "N1", mean1 = "Mean1", sd1 = "SD1", n2 = "N2", mean2 = "Mean2", sd2 = "SD2",
    n_control = "control N", k = "number of comparisons (k)"
  ),
  pt = list(
    se = "EP", n = "n", lower_bound = "limite inferior", upper_bound = "limite superior",
    q1 = "Q1", q3 = "Q3", min_val = "mínimo", med_val = "mediana", max_val = "máximo",
    sd_base = "DP na linha de base", sd_final = "DP na medida final", r = "correlação r",
    n1 = "N1", mean1 = "Média1", sd1 = "DP1", n2 = "N2", mean2 = "Média2", sd2 = "DP2",
    n_control = "N do controle", k = "número de comparações (k)"
  )
)

scenario_labels <- list(
  en = list(S1 = "minimum, median, maximum", S2 = "Q1, median, Q3",
            S3 = "minimum, Q1, median, Q3, maximum"),
  pt = list(S1 = "mínimo, mediana, máximo", S2 = "Q1, mediana, Q3",
            S3 = "mínimo, Q1, mediana, Q3, máximo")
)

messages <- list(
  en = list(
    missing_input = function(args) {
      fields <- vapply(args$fields, function(k) field_label(k, "en"), character(1))
      paste0("Missing or invalid input: ", paste(fields, collapse = ", "), ".")
    },
    invalid_value = function(args) {
      paste0("Invalid value for ", field_label(args$field, "en"), ".")
    },
    ci_upper_lt_lower = function(args) "Upper bound must be at least the lower bound.",
    iqr_q3_lt_q1 = function(args) "Q3 must be at least Q1.",
    hozo_order = function(args) "The values must satisfy minimum <= median <= maximum.",
    median_scenario_not_detected = function(args) {
      "Provide minimum, median, and maximum (S1); Q1, median, and Q3 (S2); or all five values (S3), plus n."
    },
    median_quantiles_unsorted = function(args) {
      "The quantiles must be non-decreasing: minimum <= Q1 <= median <= Q3 <= maximum."
    },
    sd_change_negative = function(args) {
      sprintf(
        "SD_base^2 + SD_final^2 - 2 * r * SD_base * SD_final is negative (%s) at r = %s. Try a lower r or check the input SDs.",
        args$value, args$r
      )
    },
    combine_n_too_small = function(args) "N1 + N2 must be greater than 1.",
    combine_need_two_groups = function(args) "Provide at least 2 groups with matching N, mean, and SD values.",
    split_n_lt_k = function(args) {
      sprintf(
        "The control N (%s) is smaller than the number of comparisons (%s), so at least one comparison would receive no participants.",
        args$n_control, args$k
      )
    },
    split_arm_n_length = function(args) {
      sprintf("Proportional splitting needs one intervention arm size for each of the %s comparisons.", args$k)
    },
    split_arm_n_positive = function(args) "Every intervention arm size must be greater than 0."
  ),
  pt = list(
    missing_input = function(args) {
      fields <- vapply(args$fields, function(k) field_label(k, "pt"), character(1))
      paste0("Entrada ausente ou inválida: ", paste(fields, collapse = ", "), ".")
    },
    invalid_value = function(args) {
      paste0("Valor inválido para ", field_label(args$field, "pt"), ".")
    },
    ci_upper_lt_lower = function(args) "O limite superior deve ser maior ou igual ao limite inferior.",
    iqr_q3_lt_q1 = function(args) "Q3 deve ser maior ou igual a Q1.",
    hozo_order = function(args) "Os valores devem satisfazer mínimo <= mediana <= máximo.",
    median_scenario_not_detected = function(args) {
      "Informe mínimo, mediana e máximo (S1); Q1, mediana e Q3 (S2); ou os cinco valores (S3), além de n."
    },
    median_quantiles_unsorted = function(args) {
      "Os quantis devem estar em ordem não decrescente: mínimo <= Q1 <= mediana <= Q3 <= máximo."
    },
    sd_change_negative = function(args) {
      sprintf(
        "DP_base^2 + DP_final^2 - 2 * r * DP_base * DP_final é negativo (%s) para r = %s. Tente um r menor ou verifique os DPs informados.",
        args$value, args$r
      )
    },
    combine_n_too_small = function(args) "N1 + N2 deve ser maior que 1.",
    combine_need_two_groups = function(args) "Informe pelo menos 2 grupos com valores correspondentes de N, média e DP.",
    split_n_lt_k = function(args) {
      sprintf(
        "O N do controle (%s) é menor que o número de comparações (%s), de modo que pelo menos uma comparação ficaria sem participantes.",
        args$n_control, args$k
      )
    },
    split_arm_n_length = function(args) {
      sprintf("A divisão proporcional exige o tamanho de um braço de intervenção para cada uma das %s comparações.", args$k)
    },
    split_arm_n_positive = function(args) "Cada tamanho de braço de intervenção deve ser maior que 0."
  )
)

#' Determine the active language from a query string
#'
#' @param search a "?key=value&..." query string (leading "?" optional)
#' @return "en" (default) or "pt"
get_lang_from_search <- function(search) {
  q <- shiny::parseQueryString(search)
  lang <- q$lang
  if (is.null(lang) || !(lang %in% c("en", "pt"))) "en" else lang
}

#' Determine the active language from a Shiny request object
#'
#' Used in app_ui.R's function-based UI, where `request$QUERY_STRING` holds
#' the original page request's query string and is available synchronously.
#'
#' @param request the `request` argument passed to a function-based Shiny UI
#' @return "en" (default) or "pt"
get_lang <- function(request) {
  get_lang_from_search(request$QUERY_STRING)
}

#' Look up a static UI string, falling back to English if missing
tr <- function(key, lang) {
  v <- ui_text[[lang]][[key]]
  if (is.null(v)) ui_text[["en"]][[key]] else v
}

#' Look up a field's short display label, falling back to English/the raw key
field_label <- function(key, lang) {
  v <- field_labels[[lang]][[key]]
  if (!is.null(v)) return(v)
  v <- field_labels[["en"]][[key]]
  if (!is.null(v)) v else key
}

#' Look up a scenario's display label, falling back to English/the raw code
scenario_label <- function(code, lang) {
  v <- scenario_labels[[lang]][[code]]
  if (!is.null(v)) return(v)
  v <- scenario_labels[["en"]][[code]]
  if (!is.null(v)) v else code
}

#' Render a calculator's message code + args into display text
render_message <- function(code, args, lang) {
  if (is.null(code) || code == "") return("")
  fn <- messages[[lang]][[code]]
  if (is.null(fn)) fn <- messages[["en"]][[code]]
  if (is.null(fn)) return(code)
  fn(args)
}
