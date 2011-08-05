/*
Copyright 2008-2010 Gephi
Authors : Mathieu Bastian <mathieu.bastian@gephi.org>
Website : http://www.gephi.org

This file is part of Gephi.

Gephi is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

Gephi is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with Gephi.  If not, see <http://www.gnu.org/licenses/>.
 */
package org.gephi.desktop.ranking;

import java.awt.Component;
import java.beans.PropertyChangeEvent;
import javax.swing.JList;
import org.gephi.ranking.spi.TransformerUI;
import java.awt.BorderLayout;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.awt.event.ItemEvent;
import java.awt.event.ItemListener;
import java.beans.PropertyChangeListener;
import javax.swing.BorderFactory;
import javax.swing.DefaultComboBoxModel;
import javax.swing.DefaultListCellRenderer;
import javax.swing.JPanel;
import javax.swing.SwingUtilities;
import org.gephi.ranking.api.Ranking;
import org.gephi.ranking.api.RankingController;
import org.gephi.ranking.api.Transformer;
import org.gephi.ui.components.SplineEditor.SplineEditor;
import org.openide.util.Lookup;
import org.openide.util.NbBundle;

/**
 *
 * @author Mathieu Bastian
 */
public class RankingChooser extends javax.swing.JPanel implements PropertyChangeListener {

    private final String NO_SELECTION;
    private final ItemListener rankingItemListener;
    private final RankingUIController controller;
    private RankingUIModel model;
    private JPanel centerPanel;
    //Spline
    private SplineEditor splineEditor;
    private org.jdesktop.animation.timing.interpolation.Interpolator interpolator;

    public RankingChooser(RankingUIController controller) {
        NO_SELECTION = NbBundle.getMessage(RankingChooser.class, "RankingChooser.choose.text");
        this.controller = controller;
        initComponents();
        initApply();

        rankingItemListener = new ItemListener() {

            public void itemStateChanged(ItemEvent e) {
                if (model != null) {
                    if (!rankingComboBox.getSelectedItem().equals(NO_SELECTION)) {
                        model.setCurrentRanking((Ranking) rankingComboBox.getSelectedItem());
                    } else {
                        model.setCurrentRanking(null);
                    }
                }
            }
        };
        rankingComboBox.setRenderer(new RankingListCellRenderer());
    }

    public void refreshModel(RankingUIModel model) {
        if (this.model != null) {
            this.model.removePropertyChangeListener(this);
        }
        this.model = model;
        if (model != null) {
            model.addPropertyChangeListener(this);
        }

        refreshModel();
    }

    private void refreshModel() {
        //CenterPanel
        if (centerPanel != null) {
            remove(centerPanel);
        }
        applyButton.setVisible(false);
        splineButton.setVisible(false);

        if (model != null) {

            //Ranking
            Ranking selectedRanking = refreshCombo();

            if (selectedRanking != null) {
                refreshTransformerPanel(selectedRanking);
            }
        }

        revalidate();
        repaint();
    }

    public void propertyChange(PropertyChangeEvent pce) {
        if (pce.getPropertyName().equals(RankingUIModel.CURRENT_ELEMENT_TYPE)) {
            refreshModel();
        } else if (pce.getPropertyName().equals(RankingUIModel.CURRENT_RANKING)
                || pce.getPropertyName().equals(RankingUIModel.CURRENT_TRANSFORMER)) {

            Ranking selectedRanking = model.getCurrentRanking();
            //CenterPanel
            if (centerPanel != null) {
                remove(centerPanel);
            }
            applyButton.setVisible(false);
            splineButton.setVisible(false);

            if (selectedRanking != null) {
                refreshTransformerPanel(selectedRanking);
            }

            revalidate();
            repaint();
        } else if (pce.getPropertyName().equals(RankingUIModel.RANKINGS)) {
            refreshCombo();
        }
    }

    private void refreshTransformerPanel(Ranking selectedRanking) {
        Transformer transformer = model.getCurrentTransformer();
        TransformerUI transformerUI = controller.getUI(transformer);
        if (!Double.isNaN(selectedRanking.getMinimumValue().doubleValue())
                && !Double.isNaN(selectedRanking.getMaximumValue().doubleValue())
                && selectedRanking.getMinimumValue() != selectedRanking.getMaximumValue()) {
            applyButton.setEnabled(true);
        } else {
            applyButton.setEnabled(false);
        }
        centerPanel = transformerUI.getPanel(transformer, selectedRanking);
        centerPanel.setBorder(BorderFactory.createCompoundBorder(BorderFactory.createEmptyBorder(5, 5, 0, 5), BorderFactory.createEtchedBorder()));
        centerPanel.setOpaque(false);
        add(centerPanel, BorderLayout.CENTER);
        applyButton.setVisible(true);
        splineButton.setVisible(true);
    }

    private Ranking refreshCombo() {
        //Ranking
        Ranking selectedRanking = model.getCurrentRanking();
        rankingComboBox.removeItemListener(rankingItemListener);
        final DefaultComboBoxModel comboBoxModel = new DefaultComboBoxModel();
        comboBoxModel.addElement(NO_SELECTION);
        comboBoxModel.setSelectedItem(NO_SELECTION);
        for (Ranking r : model.getRankings()) {
            comboBoxModel.addElement(r);
            if (selectedRanking != null && selectedRanking.getName().equals(r.getName())) {
                comboBoxModel.setSelectedItem(r);
            }
        }
        selectedRanking = model.getCurrentRanking();    //May have been refresh by the model
        rankingComboBox.addItemListener(rankingItemListener);
        SwingUtilities.invokeLater(new Runnable() {

            public void run() {
                rankingComboBox.setModel(comboBoxModel);
            }
        });
        return selectedRanking;
    }

    private void initApply() {
        applyButton.addActionListener(new ActionListener() {

            public void actionPerformed(ActionEvent e) {
                Transformer transformer = model.getCurrentTransformer();
                if (transformer != null) {
                    RankingController rankingController = Lookup.getDefault().lookup(RankingController.class);
                    if (interpolator != null) {
                        rankingController.setInterpolator(new org.gephi.ranking.api.Interpolator() {

                            public float interpolate(float x) {
                                return interpolator.interpolate(x);
                            }
                        });
                    }
                    rankingController.transform(model.getCurrentRanking(), transformer);
                }
            }
        });

        splineButton.addActionListener(new ActionListener() {

            public void actionPerformed(ActionEvent e) {
                if (splineEditor == null) {
                    splineEditor = new SplineEditor(NbBundle.getMessage(RankingChooser.class, "RankingChooser.splineEditor.title"));
                }
                splineEditor.setVisible(true);
                interpolator = splineEditor.getCurrentInterpolator();
            }
        });
    }

    @Override
    public void setEnabled(boolean enabled) {
        applyButton.setEnabled(enabled);
        rankingComboBox.setEnabled(enabled);
        splineButton.setEnabled(enabled);
    }

    /** This method is called from within the constructor to
     * initialize the form.
     * WARNING: Do NOT modify this code. The content of this method is
     * always regenerated by the Form Editor.
     */
    @SuppressWarnings("unchecked")
    // <editor-fold defaultstate="collapsed" desc="Generated Code">//GEN-BEGIN:initComponents
    private void initComponents() {
        java.awt.GridBagConstraints gridBagConstraints;

        chooserPanel = new javax.swing.JPanel();
        rankingComboBox = new javax.swing.JComboBox();
        controlPanel = new javax.swing.JPanel();
        applyButton = new javax.swing.JButton();
        splineButton = new org.jdesktop.swingx.JXHyperlink();

        setOpaque(false);
        setLayout(new java.awt.BorderLayout());

        chooserPanel.setOpaque(false);
        chooserPanel.setLayout(new java.awt.GridBagLayout());

        rankingComboBox.setToolTipText(org.openide.util.NbBundle.getMessage(RankingChooser.class, "RankingChooser.rankingComboBox.toolTipText")); // NOI18N
        rankingComboBox.setPreferredSize(new java.awt.Dimension(56, 25));
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 0;
        gridBagConstraints.gridy = 0;
        gridBagConstraints.fill = java.awt.GridBagConstraints.HORIZONTAL;
        gridBagConstraints.weightx = 1.0;
        gridBagConstraints.insets = new java.awt.Insets(5, 5, 5, 5);
        chooserPanel.add(rankingComboBox, gridBagConstraints);

        add(chooserPanel, java.awt.BorderLayout.PAGE_START);

        controlPanel.setOpaque(false);
        controlPanel.setLayout(new java.awt.GridBagLayout());

        applyButton.setIcon(new javax.swing.ImageIcon(getClass().getResource("/org/gephi/desktop/ranking/resources/apply.gif"))); // NOI18N
        applyButton.setText(org.openide.util.NbBundle.getMessage(RankingChooser.class, "RankingChooser.applyButton.text")); // NOI18N
        applyButton.setToolTipText(org.openide.util.NbBundle.getMessage(RankingChooser.class, "RankingChooser.applyButton.toolTipText")); // NOI18N
        applyButton.setMargin(new java.awt.Insets(0, 14, 0, 14));
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 1;
        gridBagConstraints.gridy = 0;
        gridBagConstraints.anchor = java.awt.GridBagConstraints.SOUTHEAST;
        gridBagConstraints.weightx = 1.0;
        gridBagConstraints.insets = new java.awt.Insets(0, 0, 3, 5);
        controlPanel.add(applyButton, gridBagConstraints);

        splineButton.setClickedColor(new java.awt.Color(0, 51, 255));
        splineButton.setText(org.openide.util.NbBundle.getMessage(RankingChooser.class, "RankingChooser.splineButton.text")); // NOI18N
        splineButton.setToolTipText(org.openide.util.NbBundle.getMessage(RankingChooser.class, "RankingChooser.splineButton.toolTipText")); // NOI18N
        splineButton.setFocusPainted(false);
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 0;
        gridBagConstraints.gridy = 0;
        gridBagConstraints.insets = new java.awt.Insets(0, 5, 0, 0);
        controlPanel.add(splineButton, gridBagConstraints);

        add(controlPanel, java.awt.BorderLayout.PAGE_END);
    }// </editor-fold>//GEN-END:initComponents
    // Variables declaration - do not modify//GEN-BEGIN:variables
    private javax.swing.JButton applyButton;
    private javax.swing.JPanel chooserPanel;
    private javax.swing.JPanel controlPanel;
    private javax.swing.JComboBox rankingComboBox;
    private org.jdesktop.swingx.JXHyperlink splineButton;
    // End of variables declaration//GEN-END:variables

    private class RankingListCellRenderer extends DefaultListCellRenderer {

        @Override
        public Component getListCellRendererComponent(JList jlist, Object o, int i, boolean bln, boolean bln1) {
            if (o instanceof Ranking) {
                return super.getListCellRendererComponent(jlist, ((Ranking) o).getDisplayName(), i, bln, bln1);
            } else {
                return super.getListCellRendererComponent(jlist, o, i, bln, bln1);
            }
        }
    }
}
