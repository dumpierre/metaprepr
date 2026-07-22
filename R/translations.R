# Translation store for DataPrepR (English primary, Portuguese optional).
#
# English is the default and the fallback for any missing key. Language is
# chosen once per session via a `?lang=pt` query parameter (see app_ui.R's
# get_lang()) and does not change reactively - switching language is a full
# page reload, which keeps this file a plain data structure with no Shiny
# reactivity of its own.
#
# Four things live here:
#   ui_text        - static app strings (nav titles, headers, help text,
#                    labels, button text)
#   field_labels    - short names for calculator inputs, used inside
#                    validation error messages (e.g. "se" -> "SE" / "EP")
#   scenario_labels - display labels for the internal S1/S2/S3 scenario
#                    codes (the codes themselves are never translated -
#                    they are matched literally in calc_median_to_mean_sd.R)
#   messages        - functions (not templates) that build the final
#                    validation/error text for each message code returned
#                    by the calc_*.R functions; one function per language so
#                    each can use its own word order and grammar

ui_text <- list(
  en = list(
    app_title = "DataPrepR",

    nav_basic_transforms = "Basic transforms",
    nav_median_estimation = "Median-based estimation",
    nav_meta_adjustments = "Meta-analysis adjustments",
    nav_workspace = "Workspace",

    nav_se = "SE -> SD",
    nav_ci = "95% CI -> SD",
    nav_iqr = "IQR -> SD",
    nav_median = "Median -> mean & SD",
    nav_sdchange = "SD of change",
    nav_combine = "Combine groups",
    nav_split = "Split shared control",

    card_se = "Standard error to standard deviation",
    card_ci = "95% confidence interval (of a mean) to standard deviation",
    card_iqr = "Interquartile range to standard deviation",
    card_median = "Median, range, or IQR to mean and standard deviation",
    card_sdchange = "Standard deviation of change from baseline",
    card_combine = "Combine k >= 2 groups (Cochrane Handbook Table 6.5.a)",
    card_split = "Split a shared control group across k comparisons",
    card_workspace = "Workspace",
    card_result = "Result",

    help_se = "SD = SE times the square root of n. Cochrane Handbook 6.5.2.2.",
    help_ci = "Assumes a symmetric 95% CI for a mean. SE = (upper - lower) / (2 times the critical value); SD = SE times the square root of n.",
    help_iqr = "SD = (Q3 - Q1) / 1.35 (normal approximation).",
    help_sdchange = "SD_change = square root of (SD_base^2 + SD_final^2 - 2 * r * SD_base * SD_final)",
    help_combine = "Edit the table below (add rows for k > 2 groups), then combine.",
    help_split = "The control N is divided into k whole parts that add back up to it exactly; mean and SD stay unchanged.",
    help_workspace = "Results sent from any calculator land here. Edit the table directly if needed.",

    help_hozo_fields = "Hozo needs minimum, median, maximum, and n (S1 only). The SD formula switches at n <= 15, n <= 70, and n > 70; the mean uses the full range formula for n <= 25, and the median alone above that.",
    help_wanluo_fields = "Wan and Luo support three scenarios. Fill in what your source reports: minimum, median, maximum (S1); Q1, median, Q3 (S2); or all five (S3). Leave the rest blank.",

    alert_ci = "The t and z critical values diverge for small n. Using z when n is small understates SD. Prefer t unless there is a specific reason to use z.",
    alert_iqr = "This assumes approximate normality. When the sample size is known, the Wan (2014) method under median-based estimation is preferable.",
    alert_sdchange = "Cochrane's default imputation is r = 0.5 when the true correlation is unknown.",
    alert_split = "This is the simple Cochrane approximation for avoiding double-counting a shared control group. For a rigorous alternative, use network or multivariate meta-analysis.",

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

    lbl_crit_method = "Critical value:",
    choice_t = "t distribution (exact, recommended)",
    choice_z = "Normal approximation (z = 1.96)",

    lbl_method = "Method:",
    choice_wan = "Wan (2014), default",
    choice_hozo = "Hozo (2005), range only",
    choice_luo = "Luo (2018) mean with Wan (2014) SD",

    btn_calculate = "Calculate",
    btn_send = "Send to workspace",
    btn_send_split = "Send all k rows to workspace",
    btn_download_csv = "Download CSV",
    btn_download_xlsx = "Download XLSX",

    lang_toggle_to_pt = "Português",
    lang_toggle_to_en = "English",

    result_awaiting = "Awaiting calculation.",
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
    combine_row_error = "Provide at least 2 complete rows (N, mean, SD).",

    method_se = "SE -> SD",
    method_iqr = "IQR -> SD",
    method_hozo = "Hozo (2005)",
    method_wan = "Wan (2014)",
    method_luo = "Luo (2018) + Wan (2014)",
    method_combine = "Combined groups",
    method_split = "Split control",

    col_study_id = "Study ID",
    col_group_label = "Group label",
    col_method = "Method",
    col_mean = "Mean",
    col_sd = "SD",
    col_n = "N"
  ),

  pt = list(
    app_title = "DataPrepR",

    nav_basic_transforms = "Transformações básicas",
    nav_median_estimation = "Estimativa baseada na mediana",
    nav_meta_adjustments = "Ajustes para metanálise",
    nav_workspace = "Área de trabalho",

    nav_se = "EP -> DP",
    nav_ci = "IC 95% -> DP",
    nav_iqr = "IQR -> DP",
    nav_median = "Mediana -> média e DP",
    nav_sdchange = "DP da mudança",
    nav_combine = "Combinar grupos",
    nav_split = "Dividir controle compartilhado",

    card_se = "Erro padrão para desvio padrão",
    card_ci = "Intervalo de confiança de 95% (de uma média) para desvio padrão",
    card_iqr = "Intervalo interquartil para desvio padrão",
    card_median = "Mediana, amplitude ou IQR para média e desvio padrão",
    card_sdchange = "Desvio padrão da mudança em relação à linha de base",
    card_combine = "Combinar k >= 2 grupos (Manual Cochrane, Tabela 6.5.a)",
    card_split = "Dividir um grupo controle compartilhado entre k comparações",
    card_workspace = "Área de trabalho",
    card_result = "Resultado",

    help_se = "DP = EP vezes a raiz quadrada de n. Manual Cochrane 6.5.2.2.",
    help_ci = "Pressupõe um IC 95% simétrico para uma média. EP = (limite superior - limite inferior) / (2 vezes o valor crítico); DP = EP vezes a raiz quadrada de n.",
    help_iqr = "DP = (Q3 - Q1) / 1,35 (aproximação normal).",
    help_sdchange = "DP_mudança = raiz quadrada de (DP_base^2 + DP_final^2 - 2 * r * DP_base * DP_final)",
    help_combine = "Edite a tabela abaixo (adicione linhas para k > 2 grupos) e depois combine.",
    help_split = "O N do controle é dividido em k partes inteiras que somam exatamente esse total; média e DP permanecem inalterados.",
    help_workspace = "Os resultados enviados de qualquer calculadora aparecem aqui. Edite a tabela diretamente, se necessário.",

    help_hozo_fields = "Hozo exige mínimo, mediana, máximo e n (apenas S1). A fórmula do DP muda em n <= 15, n <= 70 e n > 70; a média usa a fórmula completa da amplitude para n <= 25 e a mediana isolada acima disso.",
    help_wanluo_fields = "Wan e Luo aceitam três cenários. Preencha o que sua fonte relatar: mínimo, mediana, máximo (S1); Q1, mediana, Q3 (S2); ou os cinco valores (S3). Deixe o restante em branco.",

    alert_ci = "Os valores críticos t e z divergem para n pequeno. Usar z quando n é pequeno subestima o DP. Prefira t, a menos que haja um motivo específico para usar z.",
    alert_iqr = "Isso pressupõe normalidade aproximada. Quando o tamanho da amostra é conhecido, o método de Wan (2014), em estimativa baseada na mediana, é preferível.",
    alert_sdchange = "A imputação padrão do Cochrane é r = 0,5 quando a correlação verdadeira é desconhecida.",
    alert_split = "Esta é a aproximação simples do Cochrane para evitar a dupla contagem de um grupo controle compartilhado. Para uma alternativa rigorosa, use metanálise em rede ou multivariada.",

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

    lbl_crit_method = "Valor crítico:",
    choice_t = "distribuição t (exata, recomendada)",
    choice_z = "aproximação normal (z = 1,96)",

    lbl_method = "Método:",
    choice_wan = "Wan (2014), padrão",
    choice_hozo = "Hozo (2005), apenas amplitude",
    choice_luo = "Média de Luo (2018) com DP de Wan (2014)",

    btn_calculate = "Calcular",
    btn_send = "Enviar para a área de trabalho",
    btn_send_split = "Enviar todas as k linhas para a área de trabalho",
    btn_download_csv = "Baixar CSV",
    btn_download_xlsx = "Baixar XLSX",

    lang_toggle_to_pt = "Português",
    lang_toggle_to_en = "English",

    result_awaiting = "Aguardando cálculo.",
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
    combine_row_error = "Informe pelo menos 2 linhas completas (N, média, DP).",

    method_se = "EP -> DP",
    method_iqr = "IQR -> DP",
    method_hozo = "Hozo (2005)",
    method_wan = "Wan (2014)",
    method_luo = "Luo (2018) + Wan (2014)",
    method_combine = "Grupos combinados",
    method_split = "Controle dividido",

    col_study_id = "ID do estudo",
    col_group_label = "Rótulo do grupo",
    col_method = "Método",
    col_mean = "Média",
    col_sd = "DP",
    col_n = "N"
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
